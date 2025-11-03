terraform {
  required_version = ">= 1.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.15"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner     = var.owner_name
      Project   = var.project_name
      ManagedBy = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  region = var.aws_region
  state  = "available"
}

data "aws_ssm_parameter" "al2023_amd64_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "al2023_arm64_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

data "aws_ssm_parameter" "ubuntu_amd64_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_ssm_parameter" "ubuntu_arm64_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/arm64/hvm/ebs-gp3/ami-id"
}

locals {
  public_subnet_cidrs = {
    for i in range(var.az_count) :
    substr(data.aws_availability_zones.available.names[i], -2, 2) => {
      az   = data.aws_availability_zones.available.names[i]
      cidr = cidrsubnet(var.vpc_cidr, 8, 0 + 1 + i)
    }
  }

  private_subnet_cidrs = {
    for i in range(var.az_count) :
    substr(data.aws_availability_zones.available.names[i], -2, 2) => {
      az   = data.aws_availability_zones.available.names[i]
      cidr = cidrsubnet(var.vpc_cidr, 8, 128 + 1 + i)
    }
  }

  ami_al2023 = {
    amd64 = (
      var.static_al2023_amd64 != null ?
      var.static_al2023_amd64 :
      data.aws_ssm_parameter.al2023_amd64_ami.value
    ),
    arm64 = (
      var.static_al2023_arm64 != null ?
      var.static_al2023_arm64 :
      data.aws_ssm_parameter.al2023_arm64_ami.value
    )
  }

  ami_ubuntu = {
    amd64 = (
      var.static_ubuntu_amd64 != null ?
      var.static_ubuntu_amd64 :
      data.aws_ssm_parameter.ubuntu_amd64_ami.value
    ),
    arm64 = (
      var.static_ubuntu_arm64 != null ?
      var.static_ubuntu_arm64 :
      data.aws_ssm_parameter.ubuntu_arm64_ami.value
    )
  }
}

module "network" {
  source = "./modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
  region               = var.aws_region
  domain_name          = var.domain_name
}

module "security" {
  source = "./modules/security"

  project_name   = var.project_name
  vpc_id         = module.network.vpc_id
  vpc_cidr_block = var.vpc_cidr
}

module "compute_nat" {
  source = "./modules/compute_nat"

  project_name                  = var.project_name
  bastion_instance              = var.bastion_instance
  ami_id                        = local.ami_al2023
  public_subnet_describe        = module.network.public_subnet_describe
  bastion_key_pair_name         = module.security.key_pairs["bastion"].key_name
  bastion_instance_profile_name = module.security.bastion_instance_profile_name
  bastion_security_group_id     = module.security.bastion_security_group_id

  private_subnet_describe = module.network.private_subnet_describe

  route53_zone_id = module.network.route53_zone_id
  domain_name     = var.domain_name
}

resource "local_file" "bastion" {
  filename        = "./bastion.pem"
  content         = module.security.key_pairs["bastion"].payload
  file_permission = "0600"
}

resource "local_file" "workload" {
  filename        = "./workload.pem"
  content         = module.security.key_pairs["workload"].payload
  file_permission = "0600"
}

