# Fetch existing subnets by their CIDR blocks
data "aws_subnet" "private_subnet_1" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.4.0/24"]
  }
  vpc_id = data.aws_vpc.main1.id
}

data "aws_subnet" "private_subnet_2" {
  filter {
    name   = "cidrBlock"
    values = ["10.0.5.0/24"]
  }
  vpc_id = data.aws_vpc.main1.id
}

# Fetch existing security group for RDS instance (if it exists)
data "aws_security_group" "rds_sg" {
  filter {
    name   = "tag:Name"
    values = ["rds-sg"]
  }
  vpc_id = data.aws_vpc.main1.id
}

# Create the security group if it doesn't exist
resource "aws_security_group" "rds_sg" {
  count       = length(data.aws_security_group.rds_sg.id) == 0 ? 1 : 0
  name        = "rds-sg"
  description = "Security Group for RDS instance"
  vpc_id      = data.aws_vpc.main1.id

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

# Create DB Subnet Group for RDS (no data lookup, directly create it)
resource "aws_db_subnet_group" "default" {
  name        = "default-subnet-group"
  subnet_ids  = [
    data.aws_subnet.private_subnet_1.id,
    data.aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "default-subnet-group"
  }
}

# Fetch existing DB instance by its identifier
data "aws_db_instance" "app_db_instance" {
  db_instance_identifier = "app-db-instance"  # Use the actual instance identifier if available
}

# Create RDS Instance if it doesn't already exist
resource "aws_db_instance" "app_db_instance" {
  count = length(data.aws_db_instance.app_db_instance.id) == 0 ? 1 : 0
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
  value = aws_db_instance.app_db_instance[0].endpoint
}

output "rds_port" {
  value = aws_db_instance.app_db_instance[0].port
}
