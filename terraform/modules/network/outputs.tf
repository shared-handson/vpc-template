######################################################################
# VPC関連
######################################################################
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "route53_zone_id" {
  description = "ID of Route53 host zone id"
  value       = aws_route53_zone.private.id
}


######################################################################
# サブネット関連
######################################################################
output "public_subnet_describe" {
  description = "Public subnets describe"
  value = {
    for key, value in var.public_subnet_cidrs :
    key => {
      az        = value.az
      cidr      = value.cidr
      subnet_id = aws_subnet.public[key].id
      rtb_id    = aws_route_table.public.id
    }
  }
}

output "private_subnet_describe" {
  description = "Private subnets describe"
  value = {
    for key, value in var.private_subnet_cidrs :
    key => {
      az        = value.az
      cidr      = value.cidr
      subnet_id = aws_subnet.private[key].id
      rtb_id    = aws_route_table.private[key].id
    }
  }
}


######################################################################
# キーペア関連
######################################################################
output "key_pairs" {
  description = "EC2 Key Pairs"
  value = {
    natbastion = {
      key_name = aws_key_pair.natbastion.key_name
      payload  = tls_private_key.natbastion.private_key_openssh
    },
    workload = {
      key_name = aws_key_pair.workload.key_name
      payload  = tls_private_key.workload.private_key_openssh
    }
  }
  sensitive = true
}


######################################################################
# nat_bastion関連
######################################################################
output "natbastion_nw" {
  description = "Instance network parameter"
  value = {
    bastion = {
      id         = aws_instance.main.id
      private_ip = aws_instance.main.private_ip
      public_ip  = aws_eip.main.public_ip
      az_2word   = substr(aws_instance.main.availability_zone, -2, 2)
    }
  }
}

output "natbastion_eip" {
  description = "NAT Bastion EIP"
  value       = "${aws_eip.main.public_ip}/32"
}
