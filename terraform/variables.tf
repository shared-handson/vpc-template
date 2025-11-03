variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "owner_name" {
  description = "Owner name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "az_count" {
  description = "Count of AZ"
  type        = string
  default     = "3"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "domain_name" {
  description = "Domain name for the private hosted zone"
  type        = string
  default     = "internal"
}

variable "static_al2023_amd64" {
  description = "Static AMI ID for al2023_amd64"
  type        = string
  default     = null
}

variable "static_al2023_arm64" {
  description = "Static AMI ID for al2023_arm64"
  type        = string
  default     = null
}

variable "static_ubuntu_amd64" {
  description = "Static AMI ID for ubuntu_amd64"
  type        = string
  default     = null
}

variable "static_ubuntu_arm64" {
  description = "Static AMI ID for ubuntu_arm64"
  type        = string
  default     = null
}

variable "bastion_instance" {
  description = "Configuration for bastion instances"
  type = object({
    instance_type    = string
    architecture     = string
    az_2word         = string
    root_volume_size = number
  })
  default = {
    instance_type    = "t4g.nano"
    architecture     = "arm64"
    az_2word         = "1a"
    root_volume_size = 20
  }
}
