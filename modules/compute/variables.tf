variable "name" {
  description = "Name prefix for every resource. Must start with the project prefix allowed by the apply role (e.g. tf-painel-dev)."
  type        = string
}

variable "environment" {
  description = "Environment name shown on the status page."
  type        = string
}

variable "app_version" {
  description = "Version string shown on the status page (usually the git SHA or release tag)."
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC where the instance and the ALB live."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets (used by the ALB and by the instance when there is no NAT)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnets are required (ALB needs two AZs)."
  }
}

variable "private_subnet_ids" {
  description = "Private subnets (used by the instance when NAT is enabled)."
  type        = list(string)
}

variable "use_private_subnets" {
  description = "Place the instance in a private subnet. Only valid when the VPC has a NAT Gateway (see ADR-0003)."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t4g.micro", "t4g.small"], var.instance_type)
    error_message = "instance_type must be one of t3.micro, t3.small, t4g.micro, t4g.small (cost guardrail)."
  }
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 30
    error_message = "root_volume_size must be between 8 and 30 GiB."
  }
}

variable "enable_alb" {
  description = "Create an internet-facing Application Load Balancer in front of the instance (~US$16/month)."
  type        = bool
  default     = false
}

variable "alb_ingress_cidrs" {
  description = "CIDRs allowed to reach the ALB on port 80."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Extra tags merged into every resource."
  type        = map(string)
  default     = {}
}

variable "permissions_boundary_arn" {
  description = "IAM permissions boundary attached to every role this module creates (required by the pipeline apply role)."
  type        = string
  default     = null
}
