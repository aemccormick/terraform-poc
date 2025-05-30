# Create example EC2 instance and associated AWS resources
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.iam_for_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "iam_for_instance" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = var.name
  role = aws_iam_role.iam_for_instance.name
}

resource "aws_security_group" "instance" {
  name_prefix = var.name
  description = "Allow all outbound traffic for instance."
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports and protocols
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "example_instance" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.instance.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.id

  user_data      = <<-EOF
    #!/bin/bash

    # Set hostname
    hostnamectl set-hostname ${var.name}

    # Trust Aembit Tenant Root CA
    yum update -y
    yum install -y ca-certificates wget dmidecode
    wget https://${var.aembit_tenant_id}.aembit.io/api/v1/root-ca \
      -O /etc/pki/ca-trust/source/anchors/aembit-tenant-root-ca.crt
    update-ca-trust

    # Install Aembit Agent Proxy
    wget https://releases.aembit.io/agent_proxy/${var.proxy_version_number}/linux/amd64/aembit_agent_proxy_linux_amd64_${var.proxy_version_number}.tar.gz
    tar xf aembit_agent_proxy_linux_amd64_${var.proxy_version_number}.tar.gz
    cd aembit_agent_proxy_linux_amd64_${var.proxy_version_number}
    AEMBIT_AGENT_CONTROLLER=${var.aembit_agent_controller_url} AEMBIT_STEERING_ALLOWED_HOSTS=bigquery.googleapis.com ./install
  EOF

  tags = {
    Name = var.name
  }
}


# Configure GCP service account and BigQuery permissions
resource "google_service_account" "bigquery" {
  account_id                   = "aembit-bigquery-example"
  display_name                 = "aembit-bigquery-example"
  description                  = "Aembit service account for accessing BigQuery"
  create_ignore_already_exists = true
  project                      = var.gcp_project
}

resource "google_project_iam_member" "bigquery" {
  project = var.gcp_project
  role    = "roles/bigquery.admin"
  member  = "serviceAccount:${google_service_account.bigquery.email}"
}

resource "google_service_account_iam_member" "allow_impersonation" {
  service_account_id = google_service_account.bigquery.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${var.workload_identity_pool}/subject/${var.aembit_tenant_id}"
}

# Create Aembit access policy for EC2 instance
module "aembit_instance" {
  source                      = "../aembit-access-policies/"
  create_client_workload      = true
  create_trust_providers      = true
  create_credential_providers = true
  client_workload_identities = [
    {
      type  = "hostname"
      value = var.name
    },
  ]
  access_policies = {
    gcp-bigquery-example = {
      is_active                = true
      server_workload_name     = "gcp-bigquery-example"
      credential_provider_name = "gcp-bigquery-example"
    }
  }
  trust_providers = {
    aws_role = {
      type = "aws_role"
      aws_role = {
        account_id = var.aws_account_id
        role_arn   = "arn:aws:sts::${var.aws_account_id}:assumed-role/${aws_iam_role.iam_for_instance.name}/*"
      }
    }
  }
  client_workload_name = var.name
  credential_providers = {
    gcp-bigquery-example = {
      is_active = true
      type      = "google_workload_identity"
      google_workload_identity = {
        audience        = "//iam.googleapis.com/${var.workload_identity_pool_provider}"
        service_account = google_service_account.bigquery.email
      }
    }
  }
}
