output "vpc_id" {
  description = "VPC ID."
  value       = module.network.vpc_id
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = module.compute.instance_id
}

output "subnet_tier" {
  description = "Instance placement (public/private)."
  value       = module.compute.subnet_tier
}

output "url" {
  description = "Status page URL (ALB only)."
  value       = module.compute.url
}

output "ssm_session_command" {
  description = "Open a shell on the instance."
  value       = module.compute.ssm_session_command
}
