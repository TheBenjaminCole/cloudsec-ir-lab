###########################
# EC2 Instance Bastion Host
###########################

resource "aws_instance" "bastion" {
  ami                    = "ami-0341d95f75f311023"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = var.key_pair_name
  tags                   = { Name = "cloudsec_ir_lab-bastion" }
}

####################
# EC2 for Juice Shop
####################

resource "aws_instance" "juice_shop" {
  ami                         = "ami-0341d95f75f311023"
  instance_type               = "t3.medium"
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = [aws_security_group.juice_shop_sg.id]
  subnet_id                   = aws_subnet.private.id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.juice_shop_profile.name

  tags = {
    Name = "juice-shop-private"
  }
}


######################
# NAT Instance
######################

resource "aws_instance" "nat_instance" {
  ami                         = "ami-0341d95f75f311023"
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]

  source_dest_check = false

  tags = {
    Name = "cloudsec_ir_lab-nat_instance"
  }
}

