#####################
# SG for Bastion Host
#####################

resource "aws_security_group" "bastion_sg" {
  name        = "cloudsec-ir-lab-bastion-sg"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "bastion-sg"
    Environment = "lab"
  }
}


#######################
# SG for Juice Shop EC2
#######################

resource "aws_security_group" "juice_shop_sg" {
  name        = "cloudsec-ir-lab-juice-shop-sg"
  description = "Allow traffic from bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "juice-shop-sg"
    Environment = "lab"
  }
} #####Last thing made was SG for Juice shop and NAT


########
# NAT SG
########

resource "aws_security_group" "nat_sg" {
  name        = "nat_sg"
  description = "Allow NAT traffic from inside the VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [aws_vpc.main.cidr_block
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat-sg"
  }
}

# Generate a private key

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Create AWS Key Pair
resource "aws_key_pair" "ec2_key" {
  key_name = "cloudsec-ir-lab-key-2"
  public_key = tls_private_key.ec2_key.public_key_openssh
}


