output "instance_nw" {
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

output "eip_nat" {
  description = "NAT EIP"
  value       = "${aws_eip.main.public_ip}/32"
}
