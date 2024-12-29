# variables.tf

variable "aws_region" {
  default = "eu-central-1"
}

variable "aws_iam_user" {
  default = "MDP-USER"
}

variable "aws_iam_role" {
  default = "CustomAdminRole"
}

variable "vpc_id" {
  default = "vpc-073a7a8647eec235c"
}

variable "app_db_username" {
  description = "The username for the application database."
  default     = "app_user"
}

variable "app_db_password" {
  description = "The password for the application database."
  default     = "securepassword1"  # Set a secure password
}

variable "auth_db_username" {
  description = "The username for the authentication database."
  default     = "auth_user"
}

variable "auth_db_password" {
  description = "The password for the authentication database."
  default     = "securepassword2"  # Set a secure password
}
