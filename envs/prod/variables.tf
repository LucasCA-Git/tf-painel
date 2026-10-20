variable "aws_region" {
  description = "AWS region of the environment."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used as resource name prefix."
  type        = string
  default     = "tf-painel"
}

variable "repository" {
  description = "Repository that manages this stack (tag only)."
  type        = string
  default     = "LucasCA-Git/tf-painel"
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the environment VPC."
  type        = string
}

# --- Flags controladas pelo painel (GitHub Environment Variables, ADR-0004) ---

variable "enable_nat_gateway" {
  description = "Panel flag ENABLE_NAT_GATEWAY: NAT Gateway + private placement for the instance."
  type        = bool
  default     = false
}

variable "enable_alb" {
  description = "Panel flag ENABLE_ALB: public Application Load Balancer."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "Panel flag INSTANCE_TYPE: EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "enable_flow_logs" {
  description = "Send rejected traffic to CloudWatch Logs."
  type        = bool
  default     = false
}
