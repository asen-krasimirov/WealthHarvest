# Data source to fetch existing EKS Cluster
data "aws_eks_cluster" "existing_cluster" {
  name = "my-eks-cluster"
}

# Data source to get the existing EKS cluster's kubeconfig
data "aws_eks_cluster_auth" "existing_cluster_auth" {
  name = data.aws_eks_cluster.existing_cluster.name
}

# Data source to get subnets
data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_eks_cluster.existing_cluster.vpc_id
}

# Create a new IAM Role for the Node Group (if it doesn't exist)
resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect   = "Allow"
        Sid      = ""
      }
    ]
  })
}

# Attach the necessary IAM policies to the Node Group role
resource "aws_iam_role_policy_attachment" "eks_node_group_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "vpc_cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Create a Managed Node Group for EKS
resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = data.aws_eks_cluster.existing_cluster.name
  node_group_name = "my-node-group"
  node_role       = aws_iam_role.node_group_role.arn
  subnet_ids      = data.aws_subnet_ids.selected.ids

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t3.nano"]  # Adjust instance type as needed

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_readonly,
    aws_iam_role_policy_attachment.vpc_cni_policy
  ]
}
