# Define the AWS provider
provider "aws" {
  region = var.aws_region
}

# Create the auth ECR repository
resource "aws_ecr_repository" "auth_repo" {
  name                 = "auth"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "auth-repo"
  }
}

# Create the backend ECR repository
resource "aws_ecr_repository" "backend_repo" {
  name                 = "backend"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "backend-repo"
  }
}

# Output the repository URIs
output "auth_ecr_uri" {
  description = "The ECR URI for the auth repository"
  value       = aws_ecr_repository.auth_repo.repository_url
}

output "backend_ecr_uri" {
  description = "The ECR URI for the backend repository"
  value       = aws_ecr_repository.backend_repo.repository_url
}
