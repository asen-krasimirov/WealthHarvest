# Configure the AWS provider to use the region from the variable

# Use the existing VPC by its ID
data "aws_vpc" "main1" {
  id = var.vpc_id  # Replace with your existing VPC ID
}

# Reference the existing Internet Gateway by its ID
data "aws_internet_gateway" "existing_gw" {
  internet_gateway_id = var.internet_gateway_id  # Use the existing IGW ID
}

# Check for the existing Public Subnet
data "aws_subnet" "existing_public_subnet" {
  filter {
    name   = "cidr-block"
    values = ["10.0.14.0/24"]  # CIDR block for the public subnet
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Check for the existing Private Subnet
data "aws_subnet" "existing_private_subnet" {
  filter {
    name   = "cidr-block"
    values = ["10.0.15.0/24"]  # CIDR block for the private subnet
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Create Public Subnet only if it doesn't already exist
resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_subnet.existing_public_subnet.id) == 0 ? 1 : 0
  vpc_id                  = data.aws_vpc.main1.id  # Reference the existing VPC
  cidr_block              = "10.0.14.0/24"  # Adjust this as needed
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true  # Public subnet, allows public IPs for instances

  tags = {
    Name = "public-subnet"
  }
}

# Create Private Subnet only if it doesn't already exist
resource "aws_subnet" "private_subnet" {
  count                   = length(data.aws_subnet.existing_private_subnet.id) == 0 ? 1 : 0
  vpc_id                  = data.aws_vpc.main1.id  # Reference the existing VPC
  cidr_block              = "10.0.15.0/24"  # Private subnet CIDR block
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false  # Private subnet, no public IPs

  tags = {
    Name = "private-subnet"
  }
}
