variable "aembit_tenant_id" {
  type        = string
  description = "ID of Aembit tenant."
}

variable "vpc_id" {
  type        = string
  description = "ID of AWS VPC where Aembit edge components will be deployed."
}

variable "subnet_ids" {
  type        = set(string)
  description = "List of subnet IDs where Aembit edge components will be deployed."
}

variable "aws_account_id" {
  type        = string
  description = "ID of AWS where Aembit edge components will be deployed."
}

variable "aws_region" {
  type        = string
  description = "AWS region where Aembit edge components will be deployed."
}

variable "aembit_agent_log_level" {
  type        = string
  description = "Log level of Aembit agent proxy Lambda extension."
  default     = "info"
}

variable "aembit_agent_controller_url" {
  type        = string
  description = "FQDN of Aembit Agent Controller."
}

variable "lambda_layer_arns" {
  type = set(string)
  description = "Set of ARNs for AWS Lambda Layers to attach to Function"
}

variable "name" {
  type = string
  description = "Name for resources created in this module"
}
