output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "azs" {
  description = "Availability zones in use."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, ordered by AZ."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets, ordered by AZ."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}

output "public_subnet_cidrs" {
  description = "CIDRs of the public subnets, keyed by AZ."
  value       = local.public_subnets
}

output "private_subnet_cidrs" {
  description = "CIDRs of the private subnets, keyed by AZ."
  value       = local.private_subnets
}

output "nat_gateway_enabled" {
  description = "Whether private subnets have outbound internet through NAT."
  value       = var.enable_nat_gateway
}

output "nat_public_ip" {
  description = "Public IP of the NAT Gateway, if enabled."
  value       = one(aws_eip.nat[*].public_ip)
}
