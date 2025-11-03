######################################################################
# bastion関連
######################################################################
resource "aws_instance" "main" {
  ami           = var.ami_id[var.bastion_instance.architecture]
  instance_type = var.bastion_instance.instance_type
  key_name      = var.bastion_key_pair_name

  subnet_id              = var.public_subnet_describe[var.bastion_instance.az_2word].subnet_id
  iam_instance_profile   = var.bastion_instance_profile_name
  vpc_security_group_ids = [var.bastion_security_group_id]

  source_dest_check           = false
  associate_public_ip_address = true
  monitoring                  = false

  root_block_device {
    volume_type = "gp3"
    volume_size = var.bastion_instance.root_volume_size
    encrypted   = true

    tags = {
      Name = "ebs-bastion-${var.project_name}"
      Type = "bastion"
      Az   = var.public_subnet_describe[var.bastion_instance.az_2word].az
    }
  }

  user_data = file("${path.module}/user-data/nat-bastion.sh")

  tags = {
    Name = "ec2-bastion-${var.project_name}"
    Type = "bastion"
    Az   = var.public_subnet_describe[var.bastion_instance.az_2word].az
  }
}

resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "eip-bastion-${var.project_name}"
    Type = "bastion"
  }
}

resource "aws_route" "main" {
  for_each = var.private_subnet_describe

  route_table_id         = each.value.rtb_id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.main.primary_network_interface_id
}


######################################################################
# 付帯サービス
######################################################################
resource "aws_route53_record" "main" {
  zone_id = var.route53_zone_id
  name    = "bastion.${var.domain_name}"
  type    = "A"
  ttl     = 3600
  records = [aws_instance.main.private_ip]
}
