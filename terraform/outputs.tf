# Outputs print useful info after terraform apply finishes
# Like: "here's your app URL"

output "app_url" {
  description = "URL to access your application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = "741116633180.dkr.ecr.us-east-1.amazonaws.com/task-manager-api"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}
