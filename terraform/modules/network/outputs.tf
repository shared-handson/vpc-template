output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

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

output "route53_zone_id" {
  description = "ID of Route53 host zone id"
  value       = aws_route53_zone.private.id
}
