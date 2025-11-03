######################################################################
# キーペア関連
######################################################################
resource "tls_private_key" "bastion" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "bastion" {
  key_name   = "kp-bastion-${var.project_name}"
  public_key = tls_private_key.bastion.public_key_openssh

  tags = {
    Name = "kp-bastion-${var.project_name}"
    Type = "bastion"
  }
}

resource "tls_private_key" "workload" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "workload" {
  key_name   = "kp-workload-${var.project_name}"
  public_key = tls_private_key.workload.public_key_openssh

  tags = {
    Name = "kp-workload-${var.project_name}"
    Type = "workload"
  }
}


######################################################################
# セキュリティグループ関連
######################################################################
resource "aws_security_group" "bastion" {
  name        = "bastion-${var.project_name}"
  description = "Security group for NAT Bastion server"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All inbound from vpc"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "SSH from all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-bastion-${var.project_name}"
    Type = "bastion"
  }
}


######################################################################
# IAM関連
######################################################################
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "role-bastion-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "role-bastion-${var.project_name}"
    Type = "bastion"
  }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "profile-bastion-${var.project_name}"
  role = aws_iam_role.bastion.name

  tags = {
    Name = "profile-bastion-${var.project_name}"
    Type = "bastion"
  }
}

