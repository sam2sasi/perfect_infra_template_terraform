terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create a VPC
resource "aws_vpc" "test_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Test-VPC"
  }
}

# Create a Public Subnet
resource "aws_subnet" "test_pubsub" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Test-VPC-PUB-SUB"
  }
}

# Create a Private Subnet
resource "aws_subnet" "test_pvtsub" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Test-VPC-PVT-SUB"
  }
}

# Create Internet Gateway 
resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "Test-VPC-IGW"
  }
}

# Create Public Route Table
resource "aws_route_table" "test_pubrt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "Test-VPC-PUB-RT"
  }
}

# Create Public Route Table Association
resource "aws_route_table_association" "pubrtasso" {
  subnet_id      = aws_subnet.test_pubsub.id
  route_table_id = aws_route_table.test_pubrt.id
}

# Create Elastic IP 
resource "aws_eip" "test_eip" {
  vpc = true
}

# Create NAT Gateway 
resource "aws_nat_gateway" "test_tnat" {
  allocation_id = aws_eip.test_eip.id
  subnet_id     = aws_subnet.test_pubsub.id

  tags = {
    Name = "Test-VPC-NAT"
  }
}

# Create Private Route Table
resource "aws_route_table" "test_pvtrt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.test_tnat.id
  }

  tags = {
    Name = "Test-VPC-PVT-RT"
  }
}

# Create Private Route Table Association
resource "aws_route_table_association" "pvtasso" {
  subnet_id      = aws_subnet.test_pvtsub.id
  route_table_id = aws_route_table.test_pvtrt.id
}

# Create Security Group
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.test_vpc.id

  tags = {
    Name = "Test-VPC-SG"
  }
}

# Security Group Ingress Rule for port 22
resource "aws_security_group_rule" "allow_all_22" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_all.id
}

# Security Group Ingress Rule for port 80
resource "aws_security_group_rule" "allow_all_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_all.id
}

# Security Group Egress Rule for all traffic
resource "aws_security_group_rule" "allow_all_traffic_ipv4" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # semantically equivalent to all ports
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.allow_all.id
}

# Create Public EC2 Instance
resource "aws_instance" "success" {
  ami                         = "ami-00fa32593b478ad6e"  # Replace with a valid AMI ID
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.test_pubsub.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  key_name                    = "mac_key"
  associate_public_ip_address = true

  tags = {
    Name = "Public-Instance"
  }
}

# Create Private EC2 Instance
resource "aws_instance" "happy" {
  ami                         = "ami-00fa32593b478ad6e"  # Replace with a valid AMI ID
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.test_pvtsub.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  key_name                    = "mac_key"
  associate_public_ip_address = false

  tags = {
    Name = "Private-Instance"
  }
}
