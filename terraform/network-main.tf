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
  natbastion_instance  = var.natbastion_instance
  ami_id               = local.ami_al2023
}

resource "local_file" "natbastion" {
  count           = var.iscreate_key_bastion ? 1 : 0
  filename        = "./natbastion.pem"
  content         = module.network.key_pairs["natbastion"].payload
  file_permission = "0600"
}

resource "local_file" "workload" {
  count           = var.iscreate_key_workload ? 1 : 0
  filename        = "./workload.pem"
  content         = module.network.key_pairs["workload"].payload
  file_permission = "0600"
}

