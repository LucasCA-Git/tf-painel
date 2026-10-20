terraform {
  required_version = ">= 1.10.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # O bootstrap usa state local: ele cria o próprio bucket de state.
  # Depois de aplicado, é possível migrar com `terraform init -migrate-state`.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = var.project
      Component  = "bootstrap"
      ManagedBy  = "terraform"
      Repository = "${var.github_owner}/${var.github_repository}"
    }
  }
}
