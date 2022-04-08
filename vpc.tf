
module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  version         = "3.11.0"
  name            = local.application
  cidr            = local.cidr[local.env].vpc
  private_subnets = local.cidr[local.env].private
  public_subnets  = local.cidr[local.env].public
  azs             = data.aws_availability_zones.current.names

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  manage_default_route_table = true
  default_route_table_tags   = { DefaultRouteTable = true }

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_flow_log                      = false #true
  create_flow_log_cloudwatch_log_group = false #true
  create_flow_log_cloudwatch_iam_role  = false #true
  #flow_log_max_aggregation_interval    = 60

  tags = local.tags
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  endpoints = {
    s3 = {
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    },
    ssm = {
      service             = "ssm"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ssmmessages = {
      service             = "ssmmessages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ec2 = {
      service             = "ec2"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ec2messages = {
      service             = "ec2messages"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    }
  }

  #tags = var.tags
}

################################################################################
# Supporting Resources
################################################################################

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.application}-vpce"
  description = "Controls access to the VPC Endpoints"
  vpc_id      = module.vpc.vpc_id

  tags = merge(
    local.tags,
    {
      "Name" = "${local.application}-vpce"
    },
  )
}
