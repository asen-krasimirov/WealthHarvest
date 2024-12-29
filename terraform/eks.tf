# eks.tf

# Fetch the existing IAM role by its name
data "aws_iam_role" "eks_role" {
  name = var.aws_iam_role
}

# Define subnets (ensure they span at least two AZs)
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = var.vpc_id
  cidr_block              = "10.0.11.0/24"
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
  iam_instance_profile = length(data.aws_iam_instance_profile.existing_worker_nodes.*.name) == 0 ? aws_iam_instance_profile.worker_nodes[0].name : data.aws_iam_instance_profile.existing_worker_nodes.name

  image_id = "ami-0c24db5b5f274e9a0"  # Example Amazon Linux AMI for EKS worker nodes

  user_data = <<-EOT
                #!/bin/bash
                set -o xtrace
                /etc/eks/bootstrap.sh ${aws_eks_cluster.eks_cluster.name}
                EOT
}

# Check if the IAM instance profile already exists
data "aws_iam_instance_profile" "existing_worker_nodes" {
  name = "eks-worker-nodes-profile"
}

# Create the IAM instance profile if it doesn't exist
resource "aws_iam_instance_profile" "worker_nodes" {
  count = length(data.aws_iam_instance_profile.existing_worker_nodes.*.name) == 0 ? 1 : 0
  name  = "eks-worker-nodes-profile"
  role  = data.aws_iam_role.eks_role.name
}

# Autoscaling Group for Worker Nodes
resource "aws_autoscaling_group" "eks_worker_group" {
  launch_configuration = aws_launch_configuration.eks_workers.id
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}
