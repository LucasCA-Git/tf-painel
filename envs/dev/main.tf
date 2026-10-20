data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  name = "${var.project}-${var.environment}"

  # Boundary criado no bootstrap; a role de apply só cria roles que o usem.
  permissions_boundary_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project}-workload-boundary"
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  enable_flow_logs   = var.enable_flow_logs

  permissions_boundary_arn = local.permissions_boundary_arn
}

module "compute" {
  source = "../../modules/compute"

  name               = local.name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  # Com NAT a instância vai para a subnet privada (ADR-0003).
  use_private_subnets = module.network.nat_gateway_enabled
  instance_type       = var.instance_type
  enable_alb          = var.enable_alb

  permissions_boundary_arn = local.permissions_boundary_arn
}
