# Fetch the existing IAM role by its name
data "aws_iam_role" "eks_role" {
  name = var.aws_iam_role
}

# Check for existing EKS Cluster
data "aws_eks_cluster" "existing_cluster" {
  name = "my-eks-cluster"
}

# Check for existing Public Subnet 1
data "aws_subnet" "existing_public_subnet_1" {
  filter {
    name   = "cidr-block"
    values = ["10.0.10.0/24"]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Check for existing Public Subnet 2
data "aws_subnet" "existing_public_subnet_2" {
  filter {
    name   = "cidr-block"
    values = ["10.0.11.0/24"]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Create Public Subnet 1 only if it doesn't already exist
resource "aws_subnet" "public_subnet_1" {
  count                   = length(data.aws_subnet.existing_public_subnet_1.id) == 0 ? 1 : 0
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                  = "public-subnet-1"
    "kubernetes.io/role/elb" = "1"
  }
}

# Create Public Subnet 2 only if it doesn't already exist
resource "aws_subnet" "public_subnet_2" {
  count                   = length(data.aws_subnet.existing_public_subnet_2.id) == 0 ? 1 : 0
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                  = "public-subnet-2"
    "kubernetes.io/role/elb" = "1"
  }
}

# EKS Cluster (create only if it doesn't already exist)
resource "aws_eks_cluster" "eks_cluster" {
  count    = length(data.aws_eks_cluster.existing_cluster.id) == 0 ? 1 : 0
  name     = "my-eks-cluster"
  role_arn = data.aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [
      length(data.aws_subnet.existing_public_subnet_1.id) > 0 ? data.aws_subnet.existing_public_subnet_1.id : aws_subnet.public_subnet_1[0].id,
      length(data.aws_subnet.existing_public_subnet_2.id) > 0 ? data.aws_subnet.existing_public_subnet_2.id : aws_subnet.public_subnet_2[0].id
    ]
  }

  tags = {
    Name = "my-eks-cluster"
  }
}

data "aws_ami" "eks_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-*-x86_64-gp2"]
  }
}

# Worker Node Group (optional, if self-managed nodes are used)
resource "aws_launch_template" "eks_workers" {
  name_prefix   = "eks-worker-config"
  instance_type = "t3.medium"

  # Ensure IAM instance profile reference is properly resolved
  iam_instance_profile {
    name = length(data.aws_iam_instance_profile.existing_worker_nodes.id) > 0 ? data.aws_iam_instance_profile.existing_worker_nodes.name : aws_iam_instance_profile.worker_nodes[0].name
  }

  # Specify the EKS cluster name explicitly
  user_data = base64encode(<<-EOT
                #!/bin/bash
                set -o xtrace
                /etc/eks/bootstrap.sh my-eks-cluster
                EOT
  ) 

  image_id = data.aws_ami.eks_amazon_linux_2.id

  lifecycle {
    create_before_destroy = true
  }
}

# Check if the IAM instance profile already exists
data "aws_iam_instance_profile" "existing_worker_nodes" {
  name = "eks-worker-nodes-profile"
}

# Create the IAM instance profile if it doesn't exist
resource "aws_iam_instance_profile" "worker_nodes" {
  count = length(data.aws_iam_instance_profile.existing_worker_nodes.id) == 0 ? 1 : 0
  name  = "eks-worker-nodes-profile"
  role  = data.aws_iam_role.eks_role.name
}

# Update the Autoscaling Group to use the launch template
resource "aws_autoscaling_group" "eks_worker_group" {
  launch_template {
    id      = aws_launch_template.eks_workers.id
    version = "$Latest"
  }
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [
    length(data.aws_subnet.existing_public_subnet_1.id) > 0 ? data.aws_subnet.existing_public_subnet_1.id : aws_subnet.public_subnet_1[0].id,
    length(data.aws_subnet.existing_public_subnet_2.id) > 0 ? data.aws_subnet.existing_public_subnet_2.id : aws_subnet.public_subnet_2[0].id
  ]
  depends_on = [aws_launch_template.eks_workers]
}
