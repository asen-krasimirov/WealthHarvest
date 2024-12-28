# Fetch the existing IAM role by its name
data "aws_iam_role" "eks_role" {
  name = var.aws_iam_user
}

# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "my-eks-cluster"
  role_arn = data.aws_iam_role.eks_role.arn  # Use the existing IAM role ARN

  vpc_config {
    subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]
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
  iam_instance_profile = data.aws_iam_role.eks_role.name

  image_id = "ami-0c24db5b5f274e9a0"  # Example Amazon Linux AMI for EKS worker nodes

  user_data = <<-EOT
                #!/bin/bash
                set -o xtrace
                /etc/eks/bootstrap.sh ${aws_eks_cluster.eks_cluster.name}
                EOT
}

# Optional: Autoscaling Group for Worker Nodes
resource "aws_autoscaling_group" "eks_worker_group" {
  launch_configuration = aws_launch_configuration.eks_workers.id
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.public_subnet.id]

  tags = [
    {
      key                 = "Name"
      value               = "eks-worker-node"
      propagate_at_launch = true
    }
  ]
}

