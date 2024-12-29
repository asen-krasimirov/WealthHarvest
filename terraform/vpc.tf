# Configure the AWS provider to use the region from the variable

# Use the existing VPC by its ID
data "aws_vpc" "main1" {
  id = var.vpc_id  # Replace with your existing VPC ID
}

# Reference the existing Internet Gateway by its ID
data "aws_internet_gateway" "existing_gw" {
  internet_gateway_id = var.internet_gateway_id  # Use the existing IGW ID
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.main1.id  # Reference the existing VPC
  cidr_block              = "10.0.0.0/24"  # Adjust this as needed
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true  # Public subnet, allows public IPs for instances

  tags = {
    Name = "public-subnet"
  }
}

# Create Private Subnet (for RDS)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = data.aws_vpc.main1.id  # Reference the existing VPC
  cidr_block              = "10.0.7.0/24"  # Private subnet CIDR block
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false  # Private subnet, no public IPs

  tags = {
    Name = "private-subnet"
  }
}
