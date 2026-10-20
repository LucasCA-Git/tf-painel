variable "aws_region" {
  description = "AWS region where the state bucket and budget live."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name, used as prefix for every resource."
  type        = string
  default     = "tf-painel"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project))
    error_message = "project must be 3-20 chars of lowercase letters, digits or hyphens."
  }
}

variable "github_owner" {
  description = "GitHub user or organization that owns the repository."
  type        = string
  default     = "LucasCA-Git"
}

variable "github_repository" {
  description = "Repository name (without owner)."
  type        = string
  default     = "tf-painel"
}

variable "environments" {
  description = "GitHub Environments allowed to assume the apply role."
  type        = set(string)
  default     = ["dev", "prod"]
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set to false if the account already has one."
  type        = bool
  default     = true
}

variable "monthly_budget_usd" {
  description = "Monthly budget limit in USD."
  type        = number
  default     = 20

  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "monthly_budget_usd must be greater than zero."
  }
}

variable "budget_alert_emails" {
  description = "E-mails notified by the budget alerts."
  type        = list(string)

  validation {
    condition     = length(var.budget_alert_emails) > 0
    error_message = "Provide at least one e-mail for budget alerts."
  }
}
