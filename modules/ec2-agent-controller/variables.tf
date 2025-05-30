variable "aembit_tenant_id" {
  type        = string
  description = "ID of Aembit tenant."
}

variable "vpc_id" {
  type        = string
  description = "ID of AWS VPC where EC2 Instance will be deployed."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where EC2 Instance will be deployed."
}

variable "aws_account_id" {
  type        = string
  description = "ID of AWS where EC2 Instance will be deployed."
}

variable "aws_region" {
  type        = string
  description = "AWS region where EC2 Instance will be deployed."
}

variable "name" {
  type = string
  description = "Name for resources created in this module"
}

variable "controller_ingress_cidr_block" {
  type = string
  description = "CIDR block that is allowed access to port 5443 on Agent Controller"
}

variable "controller_version_number" {
  type = string
  description = "Version of Aembit Agent Controller to install"
  default = "1.21.1914"
}
