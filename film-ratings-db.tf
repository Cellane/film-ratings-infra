resource "aws_ecs_service" "film_ratings_db_service" {
  name            = "film_ratings_db_service"
  cluster         = aws_ecs_cluster.film_ratings_ecs_cluster.id
  task_definition = "${aws_ecs_task_definition.film_ratings_db.family}:${max("${aws_ecs_task_definition.film_ratings_db.revision}", "${data.aws_ecs_task_definition.film_ratings_db.revision}")}"
  desired_count   = 1
  depends_on      = [aws_lb.film_ratings_nw_load_balancer]

  load_balancer {
    target_group_arn = aws_lb_target_group.film_ratings_db_target_group.arn
    container_port   = 5432
    container_name   = "film_ratings_db"
  }

  network_configuration {
    subnets         = [aws_subnet.film_ratings_public_sn_01.id, aws_subnet.film_ratings_public_sn_02.id]
    security_groups = [aws_security_group.film_ratings_public_sg.id]
  }
}

data "aws_ecs_task_definition" "film_ratings_db" {
  task_definition = "${aws_ecs_task_definition.film_ratings_db.family}"
  depends_on      = [aws_ecs_task_definition.film_ratings_db]
}

resource "aws_ecs_task_definition" "film_ratings_db" {
  family = "film_ratings_db"
  volume {
    name      = "filmdbvolume"
    host_path = "/mnt/efs/postgres"
  }
  network_mode          = "awsvpc"
  container_definitions = <<-DEFINITION
  [
    {
        "name": "film_ratings_db",
        "image": "postgres:alpine",
        "essential": true,
        "portMappings": [
        {
            "containerPort": 5432
        }
        ],
        "environment": [
        {
            "name": "POSTGRES_DB",
            "value": "filmdb"
        },
        {
            "name": "POSTGRES_USER",
            "value": "filmuser"
        },
        {
            "name": "POSTGRES_PASSWORD",
            "value": "${var.db_password}"
        }
        ],
        "mountPoints": [
            {
            "readOnly": null,
            "containerPath": "/var/lib/postgresql/data",
            "sourceVolume": "filmdbvolume"
            }
        ],
        "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
            "awslogs-group": "film_ratings_db",
            "awslogs-region": "${var.region}",
            "awslogs-stream-prefix": "ecs"
            }
        },
        "memory": 512,
        "cpu": 256
    }
  ]
DEFINITION
}
