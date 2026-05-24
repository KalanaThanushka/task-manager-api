# Variables are like function parameters for your infrastructure
# You define them here and use them across all .tf files

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name used for naming resources"
  type        = string
  default     = "task-manager-api"
}

variable "app_port" {
  description = "Port the app listens on inside the container"
  type        = number
  default     = 3000
}

variable "app_count" {
  description = "Number of containers to run"
  type        = number
  default     = 1
}

variable "ecr_image_uri" {
  description = "Full ECR image URI including tag"
  type        = string
  # No default — must be provided when running terraform
  # Example: 741116633180.dkr.ecr.us-east-1.amazonaws.com/task-manager-api:latest
}

variable "alert_email" {
  description = "Email address to receive alerts"
  type        = string
}
