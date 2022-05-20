
module "vpc" {
    source = "./module/vpc"
    name = "fargate-test"
    default_tags = var.default_tags
}

locals {
    vpc-id = module.vpc.vpc_id
    private-subnets = module.vpc.private_subnets
    public-subnets = module.vpc.public_subnets
    lb-sgs = [module.vpc.lb_security_group_id]
    task-sgs = [module.vpc.default_security_group_id]
}

resource "aws_ecs_cluster" "primary" {
  name = "ckruse-test"
  tags = var.default_tags
}


variable "backend" {
  type = map(any)
  default = {
    sensu-backend-a = {
      log-group-name = "/ecs/fargate/ckruse/backend-a"
      short-name     = "backend1"
      dns-name       = "backend-a"
    }
    sensu-backend-b = {
      log-group-name = "/ecs/fargate/ckruse/backend-b"
      short-name     = "backend2"
      dns-name       = "backend-b"
    }
    sensu-backend-c = {
      log-group-name = "/ecs/fargate/ckruse/backend-c"
      short-name     = "backend3"
      dns-name       = "backend-c"
    }
  }
}

resource "aws_cloudwatch_log_group" "backend-logs" {
  for_each = var.backend
  name     = each.value.log-group-name

  retention_in_days = 1
  tags              = var.default_tags
}

resource "aws_ecs_task_definition" "sensu-backend" {
  for_each                 = var.backend
  family                   = each.key
  tags                     = var.default_tags
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  task_role_arn            = aws_iam_role.task.arn
  execution_role_arn       = aws_iam_role.task.arn
  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.image
      cpu       = 1024
      memory    = 2048
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = each.value.log-group-name,
          "awslogs-region"        = var.region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
      command = [
        "sensu-backend",
        "start",

        "--etcd-name", each.value.short-name,
        "--etcd-advertise-client-urls", "http://${each.value.dns-name}.fargate.sensu.local:2379",
        "--etcd-initial-advertise-peer-urls", "http://${each.value.dns-name}.fargate.sensu.local:2380",
        "--etcd-listen-client-urls", "http://0.0.0.0:2379",
        "--etcd-listen-peer-urls", "http://0.0.0.0:2380",
        "--etcd-initial-cluster",
        "backend1=http://backend-a.fargate.sensu.local:2380,backend2=http://backend-b.fargate.sensu.local:2380,backend3=http://backend-c.fargate.sensu.local:2380",

        "--etcd-initial-cluster-state", "new",
        "--etcd-initial-cluster-token", "token1",
        "--state-dir", "/var/lib/sensu/sensu-backend/etcd1"
      ],
      environment = [
        { name = "SENSU_HOSTNAME", value = "${each.value.dns-name}.fargate.sensu.local" }
      ],
      portMappings = [
        { containerPort = 3000, hostPort = 3000, protocol = "tcp" },
        { containerPort = 2379, hostPort = 2379, protocol = "tcp" },
        { containerPort = 2380, hostPort = 2380, protocol = "tcp" }
      ]
    }
  ])
}

resource "aws_ecs_service" "sensu-backend" {
  for_each = var.backend

  name            = each.key
  tags            = var.default_tags
  cluster         = aws_ecs_cluster.primary.id
  task_definition = aws_ecs_task_definition.sensu-backend[each.key].arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = local.private-subnets
    assign_public_ip = true
    security_groups  = local.task-sgs
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.sensu-backend-web.arn
    container_name   = "backend"
    container_port   = 3000
  }
  service_registries {
    registry_arn   = aws_service_discovery_service.backend[each.key].arn
    container_name = "backend"
  }
}

