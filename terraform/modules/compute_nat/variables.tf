variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "bastion_instance" {
  description = "Configuration for bastion instances"
  type = object({
    instance_type    = string
    architecture     = string
    az_2word         = string
    root_volume_size = number
  })
}

variable "ami_id" {
  description = "AMI ID map"
  type = object({
    amd64 = string
    arm64 = string
  })
}

variable "public_subnet_describe" {
  description = "Public subnets describe"
  type = map(object({
    az        = string
    cidr      = string
    subnet_id = string
    rtb_id    = string
    })
  )
}

variable "bastion_key_pair_name" {
  description = "Name of the bastion EC2 Key Pair"
  type        = string
}

variable "bastion_instance_profile_name" {
  description = "IAM instance profile name for bastion host"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID for bastion host"
  type        = string
}

variable "private_subnet_describe" {
  description = "Private subnets describe"
  type = map(object({
    az        = string
    cidr      = string
    subnet_id = string
    rtb_id    = string
    })
  )
}

variable "route53_zone_id" {
  description = "ID of Route53 host zone id"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the private hosted zone"
  type        = string
}
