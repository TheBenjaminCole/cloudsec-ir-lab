variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "cloudsec-ir-lab"
}

variable "key_pair_name" {
  description = "AWS key pair for EC2 instances"
  type        = string
  default     = "cloudsec-ir-lab-key-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "my_ip" {
  description = "My workstation IPv4 CIDR for SSH access"
  type        = string
}

