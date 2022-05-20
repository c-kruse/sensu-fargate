resource "aws_lb" "lb" {
  name               = "ckruse-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.lb.id]

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
  vpc_id      = module.vpc.vpc_id
}

