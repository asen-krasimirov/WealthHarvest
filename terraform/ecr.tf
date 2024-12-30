# Define the AWS provider

# Fetch existing repositories if they exist
data "aws_ecr_repository" "auth_repo" {
  name = "auth"
}

data "aws_ecr_repository" "backend_repo" {
  name = "backend"
}

# Create the auth ECR repository only if it doesn't exist
resource "aws_ecr_repository" "auth_repo" {
  count                 = length(data.aws_ecr_repository.auth_repo.id) == 0 ? 1 : 0
  name                  = "auth"
  image_tag_mutability  = "MUTABLE"
  
  tags = {
    Name = "auth"
  }
}

# Create the backend ECR repository only if it doesn't exist
resource "aws_ecr_repository" "backend_repo" {
  count                 = length(data.aws_ecr_repository.backend_repo.id) == 0 ? 1 : 0
  name                  = "backend"
  image_tag_mutability  = "MUTABLE"

  tags = {
    Name = "backend-repo"
  }
}

# Output the repository URIs based on whether the repository was created or fetched
output "auth_ecr_uri" {
  description = "The ECR URI for the auth repository"
  value       = length(data.aws_ecr_repository.auth_repo.id) > 0 ? data.aws_ecr_repository.auth_repo.repository_url : aws_ecr_repository.auth_repo[0].repository_url
}

output "backend_ecr_uri" {
  description = "The ECR URI for the backend repository"
  value       = length(data.aws_ecr_repository.backend_repo.id) > 0 ? data.aws_ecr_repository.backend_repo.repository_url : aws_ecr_repository.backend_repo[0].repository_url
}
