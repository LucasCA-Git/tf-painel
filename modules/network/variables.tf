variable "name" {
  description = "Name prefix for every resource (e.g. tf-painel-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "vpc_cidr must be a valid IPv4 CIDR with prefix /20 or larger."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4 (ALB requires at least 2)."
  }
}

variable "subnet_newbits" {
  description = "Bits added to the VPC prefix for each subnet (16 + 8 = /24)."
  type        = number
  default     = 8
}

variable "enable_nat_gateway" {
  description = "Create a single NAT Gateway for private subnets (~US$32/month)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Send VPC Flow Logs (REJECT only) to CloudWatch Logs."
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Retention in days for the flow logs log group."
  type        = number
  default     = 7
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
