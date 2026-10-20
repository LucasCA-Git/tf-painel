# -----------------------------------------------------------------------------
# Application Load Balancer (opcional — ver ADR-0003).
# HTTP apenas na v1: HTTPS com ACM + Route 53 está no backlog.
# -----------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0

  name_prefix = "${var.name}-alb-"
  description = "tf-painel ALB - public HTTP"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name}-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:Public HTTP endpoint is the purpose of the ALB; HTTPS is in the backlog
  for_each = var.enable_alb ? toset(var.alb_ingress_cidrs) : toset([])

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "alb_to_instance" {
  count = var.enable_alb ? 1 : 0

  security_group_id            = aws_security_group.alb[0].id
  description                  = "HTTP to the instance only"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.instance.id
}

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_91:Access logs need an extra S3 bucket; out of scope for the lab
  #checkov:skip=CKV_AWS_150:Deletion protection would block the nightly destroy of dev
  #checkov:skip=CKV2_AWS_28:WAF costs ~US$5+/month; out of scope for the lab
  #checkov:skip=CKV2_AWS_20:No certificate/domain in v1, so no HTTP->HTTPS redirect
  count = var.enable_alb ? 1 : 0

  name                       = substr("${var.name}-alb", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb[0].id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378:ALB -> instance traffic stays inside the VPC; HTTPS termination is in the backlog
  count = var.enable_alb ? 1 : 0

  name                 = substr("${var.name}-tg", 0, 32)
  port                 = 80
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "this" {
  count = var.enable_alb ? 1 : 0

  target_group_arn = aws_lb_target_group.this[0].arn
  target_id        = aws_instance.this.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:HTTPS requires ACM + domain, planned in the backlog
  #checkov:skip=CKV_AWS_103:TLS policy not applicable to an HTTP listener
  count = var.enable_alb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = var.tags
}
