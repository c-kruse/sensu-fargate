resource "aws_lb" "lb" {
  name               = "ckruse-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = local.public-subnets
  security_groups    = local.lb-sgs

  enable_deletion_protection = false

  tags = var.default_tags
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sensu-backend-web.arn
  }
}

resource "aws_lb_target_group" "sensu-backend-web" {
  name        = "sensu-backend-ALL-web"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc-id
}

