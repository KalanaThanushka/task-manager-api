resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU usage is too high"
  dimensions = {
    ServiceName = aws_ecs_service.app.name
    ClusterName = aws_ecs_cluster.main.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.app_name}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Memory usage is too high"
  dimensions = {
    ServiceName = aws_ecs_service.app.name
    ClusterName = aws_ecs_cluster.main.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "no_running_tasks" {
  alarm_name          = "${var.app_name}-no-running-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "CRITICAL: No running tasks - app is down!"
  dimensions = {
    ServiceName = aws_ecs_service.app.name
    ClusterName = aws_ecs_cluster.main.name
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.app_name}-dashboard"
  dashboard_body = <<DASHBOARD
{
  "widgets": [
    {
      "type": "metric",
      "x": 0, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "CPU Utilization",
        "region": "us-east-1",
        "metrics": [["AWS/ECS", "CPUUtilization", "ServiceName", "task-manager-api-service", "ClusterName", "task-manager-api-cluster"]],
        "period": 60,
        "stat": "Average",
        "view": "timeSeries",
        "annotations": { "horizontal": [{ "label": "Threshold", "value": 80 }] }
      }
    },
    {
      "type": "metric",
      "x": 12, "y": 0, "width": 12, "height": 6,
      "properties": {
        "title": "Memory Utilization",
        "region": "us-east-1",
        "metrics": [["AWS/ECS", "MemoryUtilization", "ServiceName", "task-manager-api-service", "ClusterName", "task-manager-api-cluster"]],
        "period": 60,
        "stat": "Average",
        "view": "timeSeries",
        "annotations": { "horizontal": [{ "label": "Threshold", "value": 80 }] }
      }
    },
    {
      "type": "log",
      "x": 0, "y": 6, "width": 24, "height": 6,
      "properties": {
        "title": "Recent App Logs",
        "region": "us-east-1",
        "query": "SOURCE '/ecs/task-manager-api' | fields @timestamp, @message | sort @timestamp desc | limit 50",
        "view": "table"
      }
    }
  ]
}
DASHBOARD
}
