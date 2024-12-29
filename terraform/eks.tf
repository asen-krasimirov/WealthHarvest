# eks.tf

variable "vpc_id" {
  description = "The ID of the VPC"
}

# Fetch the existing IAM role by its name
data "aws_iam_role" "eks_role" {
  name = var.aws_iam_role
}

# Define subnets (ensure they span at least two AZs)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
    "kubernetes.io/role/elb" = "1"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = data.aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id
    ]
  }

  tags = {
    Name = "my-eks-cluster"
  }
}

# Worker Node Group (optional, if self-managed nodes are used)
resource "aws_launch_configuration" "eks_workers" {
  name          = "eks-worker-config"
  instance_type = "t3.medium"

  # Attach the existing IAM role to the worker nodes
  iam_instance_profile = aws_iam_instance_profile.worker_nodes.name

  image_id = "ami-0c24db5b5f274e9a0"  # Example Amazon Linux AMI for EKS worker nodes


