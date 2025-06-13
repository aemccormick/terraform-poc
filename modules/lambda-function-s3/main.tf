locals {
  lambda_source_hash = base64sha256(join("", [for f in fileset("src", "*") : filebase64sha256("src/${f}")]))
}

# Create example Lambda function and associated AWS resources
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.aws_account_id]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/build/lambda_function.zip"
}

resource "aws_security_group" "lambda" {
  name_prefix = var.name
  description = "Allow all outbound traffic for Lambda function."
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "all_ipv4" {
  security_group_id = aws_security_group.lambda.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports and protocols
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 14
}

resource "aws_lambda_function" "example" {
  architectures    = ["x86_64", ]
  function_name    = var.name
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  layers           = var.lambda_layer_arns

  role        = aws_iam_role.iam_for_lambda.arn
  timeout     = 60
  memory_size = 256

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      AEMBIT_AGENT_CONTROLLER = var.aembit_agent_controller_url
      AEMBIT_LOG              = var.aembit_agent_log_level
      http_proxy              = "http://localhost:8000"
      https_proxy             = "http://localhost:8000"
      SSL_CERT_FILE           = "/opt/cacert.pem"
      # This variable is only required for Python applications using the requests package
      REQUESTS_CA_BUNDLE = "/opt/cacert.pem"
    }
  }
}


# Create federated IAM Role for Aembit Credential Provider
data "aws_iam_policy_document" "federated_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:oidc-provider/${var.aembit_tenant_id}.id.useast2.aembit.io"]
    }

    condition {
      test     = "StringEquals"
      variable = "f5dc61.id.useast2.aembit.io:aud"
      values   = ["sts.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

resource "aws_iam_role" "s3_list" {
  name               = "aembit-lambda-s3-read-example"
  assume_role_policy = data.aws_iam_policy_document.federated_trust.json
}

resource "aws_iam_role_policy_attachment" "s3_list" {
  role       = aws_iam_role.s3_list.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


# Create Aembit access policy for Lambda function
module "aembit_lambda_container" {
  source                      = "../aembit-access-policies/"
  create_client_workload      = true
  create_trust_providers      = true
  create_credential_providers = true
  client_workload_identities = [
    {
      type  = "awsLambdaArn"
      value = aws_lambda_function.example.arn
    },
    # This enables aliased function invocation
    {
      type  = "awsLambdaArn"
      value = "${aws_lambda_function.example.arn}:*"
    }
  ]
  access_policies = {
    aws-s3-example = {
      is_active                = true
      server_workload_name     = "aws-s3-example"
      credential_provider_name = "aws-s3-example"
    }
  }
  trust_providers = {
    aws_role = {
      type = "aws_role"
      aws_role = {
        account_id = var.aws_account_id
        role_arn   = "arn:aws:sts::${var.aws_account_id}:assumed-role/${aws_iam_role.iam_for_lambda.name}/${aws_lambda_function.example.function_name}"
      }
    }
  }
  client_workload_name = var.name
  credential_providers = {
    aws-s3-example = {
      is_active = true
      type      = "aws_sts"
      aws_sts = {
        role_arn = aws_iam_role.s3_list.arn
      }
    }
  }
}
