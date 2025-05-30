variable "aembit_tenant_id" {
  type        = string
  description = "ID of Aembit tenant."
  default     = "f5dc61"
}

variable "vpc_id" {
  type        = string
  description = "ID of AWS VPC where EC2 Instance will be deployed."
  default     = "vpc-0b964775814fc8bc2"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where EC2 Instance will be deployed."
  default     = "subnet-0f54e8ccb262cb019"
}

variable "aws_account_id" {
  type        = string
  description = "ID of AWS where EC2 Instance will be deployed."
}

variable "aws_region" {
  type        = string
  description = "AWS region where EC2 Instance will be deployed."
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

variable "gcp_project" {
  type = string
  description = "GCP Project name"
}

variable "name" {
  type = string
  description = "Name for resources created in this module"
}

variable "proxy_version_number" {
  type = string
  description = "Version of Aembit Agent Proxy to install"
  default = "1.23.3002"
}


variable "workload_identity_pool" {
  type = string
  description = "GCP Workload Identity Pool Name"
}

variable "workload_identity_pool_provider" {
  type = string
  description = "GCP Workload Identity Pool Provider Name"
}
