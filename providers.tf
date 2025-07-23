terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.0"
    }
  }

  required_version = ">= 1.2.0"

  # Backend configuration for state management
  backend "s3" {
    bucket         = "tech-challenge-fiap-terraform-state-2025"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1" # Default region for state bucket
    encrypt        = true
    dynamodb_table = "tech-challenge-fiap-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider configuration moved to kubernetes.tf
# to avoid circular dependencies