variable "aembit_agent_log_level" {
  type        = string
  description = "Log level of Aembit agent proxy Lambda extension."
  default     = "info"
}

variable "aembit_tenant_id" {
  type        = string
  description = "ID of Aembit tenant."
}

variable "aws_account_id" {
  type        = string
  description = "ID of AWS where Aembit edge components will be deployed."
}

variable "aws_region" {
  type        = string
  description = "AWS region where Aembit edge components will be deployed."
}

variable "gcp_project" {
  type        = string
  description = "GCP Project name"
}

variable "gcp_workload_identity_pool_name" {
  type = string
  description = "Name of GCP Workload Identity Federation Pool"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where Aembit edge components will be deployed."
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block of AWS VPC"
}

variable "vpc_id" {
  type        = string
  description = "ID of AWS VPC where Aembit edge components will be deployed."
}

variable "os_type" {
  type = string
  description = "Operating System of host running Terraform."
  validation {
    condition     = var.os_type == "windows" || var.os_type == "linux"
    error_message = "The os_type must be either 'windows' or 'linux'."
  }
}
