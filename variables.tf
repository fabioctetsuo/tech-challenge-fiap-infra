# Variaveis da AWS para o provisionamento
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type        = string
  default     = "tech_challenge_cluster"
}

# Microservices configuration
variable "microservices" {
  description = "Configuration for microservices"
  type = map(object({
    name           = string
    port           = number
    replicas       = number
    cpu_limit      = string
    memory_limit   = string
    cpu_request    = string
    memory_request = string
  }))
  default = {
    products = {
      name           = "products-service"
      port           = 3001
      replicas       = 2
      cpu_limit      = "500m"
      memory_limit   = "512Mi"
      cpu_request    = "250m"
      memory_request = "256Mi"
    }
    orders = {
      name           = "orders-service"
      port           = 3002
      replicas       = 2
      cpu_limit      = "500m"
      memory_limit   = "512Mi"
      cpu_request    = "250m"
      memory_request = "256Mi"
    }
    payment = {
      name           = "payment-service"
      port           = 3003
      replicas       = 2
      cpu_limit      = "500m"
      memory_limit   = "512Mi"
      cpu_request    = "250m"
      memory_request = "256Mi"
    }
    payment-mock = {
      name           = "payment-mock-service"
      port           = 3004
      replicas       = 1
      cpu_limit      = "300m"
      memory_limit   = "256Mi"
      cpu_request    = "100m"
      memory_request = "128Mi"
    }
  }
}

# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

# Note: domain_name variable removed as ingress is not used for student accounts