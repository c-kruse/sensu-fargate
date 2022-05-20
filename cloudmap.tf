
resource "aws_service_discovery_private_dns_namespace" "fargate" {
  name        = "fargate.sensu.local"
  description = "service discovery ns for fargate experiment."
  vpc         = module.vpc.vpc_id
  tags        = var.default_tags
}

resource "aws_service_discovery_service" "backend" {
  for_each = var.backend
  name     = each.value.dns-name
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.fargate.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }
  health_check_custom_config {
    failure_threshold = 1
  }
  tags = var.default_tags
}
