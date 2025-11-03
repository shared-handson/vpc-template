variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type = map(object({
    az   = string
    cidr = string
  }))
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type = map(object({
    az   = string
    cidr = string
  }))
}

variable "region" {
  description = "Deploy Region"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the private hosted zone"
  type        = string
}
