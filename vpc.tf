module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.7.0"

  name = "ckruse-fargate-test"
  cidr = local.cidr

  azs            = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets = local.public_subnets

  private_subnets    = local.private_subnets
  single_nat_gateway = true
  enable_nat_gateway = true
  //  public_dedicated_network_acl = true
  //  public_inbound_acl_rules     = local.network_acls["inbound"]
  //  public_outbound_acl_rules    = local.network_acls["outbound"]

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.default_tags, {
    Name = "ckruse-fargate-test"
  })
}

resource "aws_security_group" "bastion" {
  name = "ckruse-fargate-test-bastion"
  tags = merge(var.default_tags, {
    Name = "ckruse-fargate-test-bastion"
  })
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "SSH"
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All"
  }
}
resource "aws_security_group" "lb" {
  name = "ckruse-fargate-test-lb"
  tags = merge(var.default_tags, {
    Name = "ckruse-fargate-test-lb"
  })
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "HTTP"
  }

  ingress {
    from_port        = 2379
    to_port          = 2380
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "ETCD"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All"
  }
}

resource "aws_security_group" "default" {
  name   = "ckruse-fargate-test"
  vpc_id = module.vpc.vpc_id
  tags = merge(var.default_tags, {
    Name = "ckruse-fargate-test-default"
  })

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "All"
  }
}


resource "aws_main_route_table_association" "a" {
  vpc_id         = module.vpc.vpc_id
  route_table_id = module.vpc.public_route_table_ids[0]
}


locals {
  cidr            = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.5.0/24"]
  private_subnets = ["10.0.21.0/24", "10.0.25.0/24"]
  network_acls = {
    inbound = [
      {
        description = "AWS Directory Services"
        rule_number = 130
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "all"
        cidr_block  = "10.10.1.0/24"
      },
      {
        description = "DNS"
        rule_number = 140
        rule_action = "allow"
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        description = "ICMP"
        rule_number = 150
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "icmp"
        cidr_block  = "0.0.0.0/0"
        icmp_type   = -1
        icmp_code   = -1
      },
      {
        description = "Internal"
        rule_number = 100
        rule_action = "allow"
        from_port   = 1
        to_port     = 9999
        protocol    = "all"
        cidr_block  = "10.0.0.0/16"
      }
    ],
    outbound = [
      {
        description = "Ephemeral ports"
        rule_number = 900
        rule_action = "allow"
        from_port   = 32768
        to_port     = 65535
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        description = "AWS Directory Services"
        rule_number = 100
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "all"
        cidr_block  = "10.10.1.0/24"
      },
      {
        description = "DNS"
        rule_number = 110
        rule_action = "allow"
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        description = "ICMP"
        rule_number = 120
        rule_action = "allow"
        from_port   = 0
        to_port     = 0
        protocol    = "icmp"
        cidr_block  = "0.0.0.0/0"
        icmp_type   = -1
        icmp_code   = -1
      },
      {
        description = "HTTP"
        rule_number = 130
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        description = "HTTPS"
        rule_number = 140
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
      },
      {
        description = "Internal"
        rule_number = 150
        rule_action = "allow"
        from_port   = 1
        to_port     = 9999
        protocol    = "all"
        cidr_block  = "10.0.0.0/16"
      }
    ]
  }
}
