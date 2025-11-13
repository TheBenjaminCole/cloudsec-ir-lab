output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

# Output private key
output "private_key_pem" {
  value = tls_private_key.ec2_key.private_key_pem
  sensitive = true
}
