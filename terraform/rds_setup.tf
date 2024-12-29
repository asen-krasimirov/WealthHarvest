# Fetch existing subnets by their CIDR blocks
data "aws_subnet" "private_subnet_1" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.12.0/24"]
  }
  vpc_id = var.vpc_id
}

data "aws_subnet" "private_subnet_2" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.13.0/24"]
  }
  vpc_id = var.vpc_id
}

data "aws_subnet" "private_subnet_3" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.16.0/24"]
  }
  vpc_id = var.vpc_id
}

# Check if the DB Subnet Group already exists
data "aws_db_subnet_group" "existing" {
  name = "default-subnet-group1"
}

# Create DB Subnet Group for RDS if it does not exist
resource "aws_db_subnet_group" "default" {
  #count        = length(data.aws_db_subnet_group.existing.id) == 0 ? 1 : 0
  name         = "default-subnet-group1"
  subnet_ids   = [
    data.aws_subnet.private_subnet_1.id,
    data.aws_subnet.private_subnet_2.id,
    data.aws_subnet.private_subnet_3.id
  ]

  tags = {
    Name = "default-subnet-group1"
  }
}

# Fetch existing security group for RDS instance (if it exists)
data "aws_security_group" "rds_sg" {
  filter {
    name   = "tag:Name"
    values = ["rds-sg"]
  }
  vpc_id = var.vpc_id
}

# Create the security group if it doesn't exist
resource "aws_security_group" "rds_sg" {
  count       = length(data.aws_security_group.rds_sg.id) == 0 ? 1 : 0
  name        = "rds-sg"
  description = "Security Group for RDS instance"
  vpc_id      = var.vpc_id

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

# Create RDS Instance unconditionally
resource "aws_db_instance" "app_db_instance" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.1"
  instance_class       = "db.t3.small"
  username             = var.app_db_username
  password             = var.app_db_password
  publicly_accessible  = false  # Ensure the RDS instance is not publicly accessible
  multi_az             = false
  storage_type         = "gp3"
  db_subnet_group_name = length(data.aws_db_subnet_group.existing.id) > 0 ? data.aws_db_subnet_group.existing.name : aws_db_subnet_group.default[0].name
  vpc_security_group_ids = aws_security_group.rds_sg.*.id

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
