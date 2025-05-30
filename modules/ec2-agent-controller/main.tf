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

resource "aws_vpc_security_group_ingress_rule" "port_5443" {
  security_group_id = aws_security_group.instance.id
  cidr_ipv4         = var.controller_ingress_cidr_block
  ip_protocol       = "tcp"
  from_port = 5443
  to_port = 5443
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

resource "aembit_agent_controller" "example" {
    name = "Agent Controller with AWS IAM Role Trust Provider"
    is_active = true

    trust_provider_id = aembit_trust_provider.example.id
}

resource "aembit_trust_provider" "example" {
    name = "EC2 Agent Controller Trust Provider"
    is_active = true
    aws_metadata = {
        account_id = var.aws_account_id
        certificate = <<-EOT
-----BEGIN CERTIFICATE-----
MIIDITCCAoqgAwIBAgIUVJTc+hOU+8Gk3JlqsX438Dk5c58wDQYJKoZIhvcNAQEL
BQAwXDELMAkGA1UEBhMCVVMxGTAXBgNVBAgTEFdhc2hpbmd0b24gU3RhdGUxEDAO
BgNVBAcTB1NlYXR0bGUxIDAeBgNVBAoTF0FtYXpvbiBXZWIgU2VydmljZXMgTExD
MB4XDTI0MDQyOTE3MTE0OVoXDTI5MDQyODE3MTE0OVowXDELMAkGA1UEBhMCVVMx
GTAXBgNVBAgTEFdhc2hpbmd0b24gU3RhdGUxEDAOBgNVBAcTB1NlYXR0bGUxIDAe
BgNVBAoTF0FtYXpvbiBXZWIgU2VydmljZXMgTExDMIGfMA0GCSqGSIb3DQEBAQUA
A4GNADCBiQKBgQCHvRjf/0kStpJ248khtIaN8qkDN3tkw4VjvA9nvPl2anJO+eIB
UqPfQG09kZlwpWpmyO8bGB2RWqWxCwuB/dcnIob6w420k9WY5C0IIGtDRNauN3ku
vGXkw3HEnF0EjYr0pcyWUvByWY4KswZV42X7Y7XSS13hOIcL6NLA+H94/QIDAQAB
o4HfMIHcMAsGA1UdDwQEAwIHgDAdBgNVHQ4EFgQUJdbMCBXKtvCcWdwUUizvtUF2
UTgwgZkGA1UdIwSBkTCBjoAUJdbMCBXKtvCcWdwUUizvtUF2UTihYKReMFwxCzAJ
BgNVBAYTAlVTMRkwFwYDVQQIExBXYXNoaW5ndG9uIFN0YXRlMRAwDgYDVQQHEwdT
ZWF0dGxlMSAwHgYDVQQKExdBbWF6b24gV2ViIFNlcnZpY2VzIExMQ4IUVJTc+hOU
+8Gk3JlqsX438Dk5c58wEgYDVR0TAQH/BAgwBgEB/wIBADANBgkqhkiG9w0BAQsF
AAOBgQAywJQaVNWJqW0R0T0xVOSoN1GLk9x9kKEuN67RN9CLin4dA97qa7Mr5W4P
FZ6vnh5CjOhQBRXV9xJUeYSdqVItNAUFK/fEzDdjf1nUfPlQ3OJ49u6CV01NoJ9m
usvY9kWcV46dqn2bk2MyfTTgvmeqP8fiMRPxxnVRkSzlldP5Fg==
-----END CERTIFICATE-----
EOT
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

    # Get Private IP for Aembit Managed Cert
    TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
    HOSTNAME=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/hostname`

    # Trust Aembit Tenant Root CA
    yum update -y
    yum install -y wget libicu

    # Install Aembit Agent Controller
    wget https://releases.aembit.io/agent_controller/${var.controller_version_number}/linux/amd64/aembit_agent_controller_linux_amd64_${var.controller_version_number}.tar.gz
    tar xf aembit_agent_controller_linux_amd64_${var.controller_version_number}.tar.gz
    cd aembit_agent_controller_linux_amd64_${var.controller_version_number}
    AEMBIT_AGENT_CONTROLLER_ID=${aembit_agent_controller.example.id} AEMBIT_TENANT_ID=${var.aembit_tenant_id} AEMBIT_MANAGED_TLS_HOSTNAME=$HOSTNAME ./install
  EOF

  tags = {
    Name = var.name
  }
}
