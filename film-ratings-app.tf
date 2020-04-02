resource "aws_ecs_service" "film_ratings_app_service" {
  name                               = "film_ratings_app_service"
  iam_role                           = aws_iam_role.ecs-service-role.name
  cluster                            = aws_ecs_cluster.film_ratings_ecs_cluster.id
  task_definition                    = "${aws_ecs_task_definition.film_ratings_app.family}:${max("${aws_ecs_task_definition.film_ratings_app.revision}", "${data.aws_ecs_task_definition.film_ratings_app.revision}")}"
  depends_on                         = [aws_ecs_service.film_ratings_db_service]
  desired_count                      = var.desired_capacity
  deployment_minimum_healthy_percent = "50"
  deployment_maximum_percent         = "100"

  lifecycle {
    ignore_changes = [task_definition]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.film_ratings_app_target_group.arn
    container_port   = 3000
    container_name   = "film_ratings_app"
  }
}

data "aws_ecs_task_definition" "film_ratings_app" {
  task_definition = aws_ecs_task_definition.film_ratings_app.family
  depends_on      = [aws_ecs_task_definition.film_ratings_app]
}

resource "aws_ecs_task_definition" "film_ratings_app" {
  family                = "film_ratings_app"
  container_definitions = <<-DEFINITION
    [
      {
        "name": "film_ratings_app",
        "image": "${var.film_ratings_app_image}",
        "essential": true,
        "portMappings": [
          {
            "containerPort": 3000,
            "hostPort": 3000
          }
        ],
        "environment": [
          {
            "name": "DB_HOST",
            "value": "${aws_lb.film_ratings_nw_load_balancer.dns_name}"
          },
          {
            "name": "DB_PASSWORD",
            "value": "${var.db_password}"
          }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
              "awslogs-group": "film_ratings_app",
              "awslogs-region": "${var.region}",
              "awslogs-stream-prefix": "ecs"
            }
        },
        "memory": 1024,
        "cpu": 256
      }
    ]
DEFINITION
}
