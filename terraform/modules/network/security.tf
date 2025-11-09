######################################################################
# キーペア関連
######################################################################
resource "tls_private_key" "natbastion" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "natbastion" {
  key_name   = "kp-natbastion-${var.project_name}"
  public_key = tls_private_key.natbastion.public_key_openssh

  tags = {
    Name = "kp-natbastion-${var.project_name}"
    Type = "natbastion"
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
resource "aws_security_group" "natbastion" {
  name        = "natbastion-${var.project_name}"
  description = "Security group for NAT Bastion server"
  vpc_id      = aws_vpc.main.id

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
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "SSH from all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-natbastion-${var.project_name}"
    Type = "natbastion"
  }
}


######################################################################
# IAM関連
######################################################################
data "aws_iam_policy_document" "natbastion" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "natbastion" {
  name               = "role-natbastion-${var.project_name}"
  assume_role_policy = data.aws_iam_policy_document.natbastion.json

  tags = {
    Name = "role-natbastion-${var.project_name}"
    Type = "natbastion"
  }
}

resource "aws_iam_role_policy_attachment" "natbastion_ssm" {
  role       = aws_iam_role.natbastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "natbastion" {
  name = "profile-natbastion-${var.project_name}"
  role = aws_iam_role.natbastion.name

  tags = {
    Name = "profile-natbastion-${var.project_name}"
    Type = "natbastion"
  }
}

