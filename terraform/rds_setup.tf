# Configure AWS provider with region variable

# Fetch VPC from vpc.tf
data "aws_vpc" "main" {
  id = aws_vpc.main.id
}

# Define two subnets in different Availability Zones for RDS
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-2"
  }
}

# Security Group for RDS instance (restricted to your VPC)
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security Group for RDS instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432  # PostgreSQL port (adjust for your DB)
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Only allow access from the same VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound traffic to anywhere
  }

  tags = {
    Name = "rds-sg"
  }
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "default" {
  name       = "default-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]  # Include both private subnets for AZ coverage

  tags = {
    Name = "default-subnet-group"
  }
}

# RDS Instance Configuration
resource "aws_db_instance" "app_db_instance" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t3.micro"
  username             = var.app_db_username
  password             = var.app_db_password
  publicly_accessible  = false  # Ensure the RDS instance is not publicly accessible
  multi_az             = false
  storage_type         = "gp2"
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "app-db-instance"
  }
}

# Outputs (Optional, to view the RDS endpoint and other details)
output "rds_endpoint" {
  value = aws_db_instance.app_db_instance.endpoint
}

output "rds_port" {
  value = aws_db_instance.app_db_instance.port
}
