# Configure the AWS provider to use the region from the variable

# Use the existing VPC by its ID
data "aws_vpc" "main" {
  id = var.vpc_id  # Replace with your existing VPC ID
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = data.aws_vpc.main.id  # Reference the existing VPC
  cidr_block              = "10.0.0.0/24"  # Adjust this as needed
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true  # Public subnet, allows public IPs for instances

  tags = {
    Name = "public-subnet"
  }
}

# Create Private Subnet (for RDS)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = data.aws_vpc.main.id  # Reference the existing VPC
  cidr_block              = "10.0.1.0/24"  # Private subnet CIDR block
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false  # Private subnet, no public IPs

  tags = {
    Name = "private-subnet"
  }
}

# Create Internet Gateway (for public subnet)
resource "aws_internet_gateway" "gw" {
  vpc_id = data.aws_vpc.main.id  # Reference the existing VPC

  tags = {
    Name = "main-vpc-gw"
  }
}
