# Configure the AWS provider to use the region from the variable
provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"  # Adjust this as needed
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true  # Public subnet, allows public IPs for instances

  tags = {
    Name = "public-subnet"
  }
}

# Create Private Subnet (for RDS)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"  # Private subnet CIDR block
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false  # Private subnet, no public IPs

  tags = {
    Name = "private-subnet"
  }
}

# Create Internet Gateway (for public subnet)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-vpc-gw"
  }
}
