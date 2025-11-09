######################################################################
# natbastion本体
######################################################################
resource "aws_instance" "main" {
  ami           = var.ami_id[var.natbastion_instance.architecture]
  instance_type = var.natbastion_instance.instance_type
  key_name      = aws_key_pair.natbastion.key_name

  subnet_id              = aws_subnet.public[var.natbastion_instance.az_2word].id
  iam_instance_profile   = aws_iam_instance_profile.natbastion.name
  vpc_security_group_ids = [aws_security_group.natbastion.id]

  source_dest_check           = false
  associate_public_ip_address = true
  monitoring                  = false

  root_block_device {
    volume_type = "gp3"
    volume_size = var.natbastion_instance.root_volume_size
    encrypted   = true

    tags = {
      Name = "ebs-natbastion-${var.project_name}"
      Type = "natbastion"
      Az   = aws_subnet.public[var.natbastion_instance.az_2word].availability_zone
    }
  }

  user_data = file("${path.module}/userdata/natbastion.sh")

  tags = {
    Name = "ec2-natbastion-${var.project_name}"
    Type = "natbastion"
    Az   = aws_subnet.public[var.natbastion_instance.az_2word].availability_zone
  }
}


######################################################################
# natbastionネットワーク
######################################################################
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "eip-natbastion-${var.project_name}"
    Type = "natbastion"
  }
}

resource "aws_route" "main" {
  for_each = var.private_subnet_cidrs

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.main.primary_network_interface_id
}

resource "aws_route53_record" "main" {
  zone_id = aws_route53_zone.private.id
  name    = "natbastion.${var.domain_name}"
  type    = "A"
  ttl     = 3600
  records = [aws_instance.main.private_ip]
}
