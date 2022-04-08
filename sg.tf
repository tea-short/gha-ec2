resource "aws_security_group" "gha" {
  name        = local.application
  description = "Github runner EC2 instance"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    local.tags,
    { Name = "gha" }
  )
}

resource "aws_security_group_rule" "https_egress" {
  description       = "Access to Internet"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.gha.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "http_egress" {
  description       = "Access to Internet"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.gha.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "vpc_endpoint_egress" {
  description              = "Access to VPC endpoints"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.gha.id
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  description              = "Access to VPC endpoints"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gha.id
  security_group_id        = aws_security_group.vpc_endpoints.id
}
