output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "private_ip" {
  description = "Private IP of the instance."
  value       = aws_instance.this.private_ip
}

output "subnet_tier" {
  description = "Where the instance was placed: public (no NAT) or private (with NAT)."
  value       = var.use_private_subnets ? "private" : "public"
}

output "security_group_id" {
  description = "Security group of the instance."
  value       = aws_security_group.instance.id
}

output "alb_dns_name" {
  description = "DNS name of the ALB, if enabled."
  value       = one(aws_lb.this[*].dns_name)
}

output "url" {
  description = "Public URL of the status page (only when the ALB is enabled)."
  value       = var.enable_alb ? "http://${aws_lb.this[0].dns_name}" : null
}

output "ssm_session_command" {
  description = "Command to open a shell on the instance through SSM Session Manager."
  value       = "aws ssm start-session --target ${aws_instance.this.id}"
}
