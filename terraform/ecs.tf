# ── IAM Role ──────────────────────────────────────────
# ECS needs permission to pull images from ECR and write logs
# IAM roles are like ID badges — they grant specific permissions

resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.app_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# Attach AWS managed policy that gives ECS the permissions it needs
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── CloudWatch Log Group ──────────────────────────────
# Where your container logs will be stored
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7    # auto delete logs after 7 days (saves cost)
}

# ── ECS Cluster ───────────────────────────────────────
# A cluster is just a logical grouping of your containers
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
}

# ── ECS Task Definition ───────────────────────────────
# A task definition is like a blueprint for your container
# It says: which image to use, how much CPU/memory, what ports, etc.
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]   # serverless containers — no EC2 to manage
  cpu                      = "256"         # 0.25 vCPU
  memory                   = "512"         # 512 MB RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name  = var.app_name
    image = var.ecr_image_uri    # the Docker image we pushed to ECR

    portMappings = [{
      containerPort = var.app_port
      protocol      = "tcp"
    }]

    # Send container logs to CloudWatch
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }

    # Health check inside the container
    healthCheck = {
      command     = ["CMD-SHELL", "node -e \"require('http').get('http://localhost:${var.app_port}/health', r => process.exit(r.statusCode === 200 ? 0 : 1))\""]
      interval    = 30
      timeout     = 5
      retries     = 3
    }
  }])
}

# ── ECS Service ───────────────────────────────────────
# A service keeps your task running
# If your container crashes, ECS service restarts it automatically
resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count    # how many containers to run
  launch_type     = "FARGATE"        # serverless — AWS manages the servers

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  # Connect service to the load balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.app_port
  }

  depends_on = [aws_lb_listener.http]
}
