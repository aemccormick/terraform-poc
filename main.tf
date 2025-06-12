# Create Aembit Agent Controller
module "ec2_agent_controller" {
  source                        = "./modules/ec2-agent-controller"
  name                          = "ec2-agent-controller"
  aembit_tenant_id              = var.aembit_tenant_id
  aws_account_id                = var.aws_account_id
  aws_region                    = var.aws_region
  controller_ingress_cidr_block = var.vpc_cidr_block
  subnet_id                     = var.subnet_ids[0]
  vpc_id                        = var.vpc_id
}

# Create Aembit Server Workload for the AWS S3 API
resource "aembit_server_workload" "s3" {
  name        = "aws-s3-example"
  description = "AWS S3"
  is_active   = true
  service_endpoint = {
    app_protocol       = "HTTP"
    host               = "s3.${var.aws_region}.amazonaws.com"
    port               = 443
    requested_port     = 443
    tls                = true
    tls_verification   = "full"
    requested_tls      = true
    transport_protocol = "TCP"
    authentication_config = {
      method = "HTTP Authentication"
      scheme = "AWS Signature v4"
    }
  }
}

# Create Lambda Layer with CA trust bundle
resource "null_resource" "trust_bundle_linux" {
  count = var.os_type == "linux" ? 1 : 0
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/layer_build.sh"
    environment = {
      "AEMBIT_TENANT_ID" = var.aembit_tenant_id
    }
  }
}

resource "null_resource" "trust_bundle_windows" {
  count = var.os_type == "windows" ? 1 : 0
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "powershell.exe -ExecutionPolicy Bypass -File ${path.module}/layer_build.ps1"
    environment = {
      "AEMBIT_TENANT_ID" = var.aembit_tenant_id
    }
  }
}

resource "aws_lambda_layer_version" "trust_bundle" {
  depends_on = [null_resource.trust_bundle_linux, null_resource.trust_bundle_windows]
  filename   = "${path.module}/build/trustbundle.zip"
  layer_name = "ca_trust_bundle"

  source_code_hash = "${path.module}/build/trustbundle.zip"
}

# Import Aembit Agent Proxy Layer
resource "aws_serverlessapplicationrepository_cloudformation_stack" "aembit_proxy_layer" {
  name           = "aembit-agent-proxy-lambda-layer"
  application_id = "arn:aws:serverlessrepo:us-east-1:833062290399:applications/aembit-agent-proxy-lambda-layer"
  capabilities   = ["CAPABILITY_IAM"]
}

# Create Lambda Function and Access Policy
module "lambda-function-s3" {
  source                      = "./modules/lambda-function-s3"
  depends_on                  = [aembit_server_workload.s3]
  name                        = "lambda-s3-example"
  aembit_agent_controller_url = module.ec2_agent_controller.agent_controller_url
  aembit_tenant_id            = var.aembit_tenant_id
  aws_account_id              = var.aws_account_id
  aws_region                  = var.aws_region
  lambda_layer_arns = [
    aws_lambda_layer_version.trust_bundle.arn,
    aws_serverlessapplicationrepository_cloudformation_stack.aembit_proxy_layer.outputs.LayerVersionArn
  ]
  subnet_ids = var.subnet_ids
  vpc_id     = var.vpc_id
}

# Create Aembit Server Workload for the Google BigQuery API
resource "aembit_server_workload" "bigquery" {
  name        = "gcp-bigquery-example"
  description = "GCP BigQuery"
  is_active   = true
  service_endpoint = {
    app_protocol       = "HTTP"
    host               = "bigquery.googleapis.com"
    port               = 443
    requested_port     = 443
    tls                = true
    tls_verification   = "full"
    requested_tls      = true
    transport_protocol = "TCP"
    authentication_config = {
      method = "HTTP Authentication"
      scheme = "Bearer"
    }
  }
}

# Configure Google Workload Identity Federation
resource "google_iam_workload_identity_pool" "aembit" {
  workload_identity_pool_id = var.gcp_workload_identity_pool_name
  project                   = var.gcp_project
}

resource "google_iam_workload_identity_pool_provider" "aembit" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.aembit.workload_identity_pool_id
  workload_identity_pool_provider_id = "aembit-provider"
  display_name                       = "aembit-provider"
  description                        = "Aembit identity pool provider"
  attribute_mapping = {
    "google.subject" = "assertion.tenant"
  }
  oidc {
    issuer_uri = "https://${var.aembit_tenant_id}.id.useast2.aembit.io"
  }
  project = var.gcp_project
}

# Create Lambda Function and Access Policy
module "ec2-bigquery" {
  source                          = "./modules/ec2-bigquery"
  depends_on                      = [aembit_server_workload.bigquery]
  name                            = "ec2-bigquery-example"
  aembit_agent_controller_url     = module.ec2_agent_controller.agent_controller_url
  aembit_tenant_id                = var.aembit_tenant_id
  aws_account_id                  = var.aws_account_id
  aws_region                      = var.aws_region
  gcp_project                     = var.gcp_project
  subnet_id                       = var.subnet_ids[0]
  vpc_id                          = var.vpc_id
  workload_identity_pool          = google_iam_workload_identity_pool.aembit.name
  workload_identity_pool_provider = google_iam_workload_identity_pool_provider.aembit.name
}
