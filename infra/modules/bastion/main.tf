data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

// EC2 INSTANCE AS BASTION HOST FOR RDS //

resource "aws_instance" "ec2_rds" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    name = "ec2 for rds"
  }
}

// BASTION HOST SECURITY GROUP //

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "bastion security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22  
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    description     = "allow ssh from my ip"
  }  

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow all outbund traffic"

  }
}



