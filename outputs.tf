# Output para exibir o ID da VPC criada
output "vpc_id" {
  value       = aws_vpc.tech_challenge_vpc.id
  description = "O ID da VPC criada"
}

output "eks_cluster_name" {
  value = aws_eks_cluster.tech_challenge_cluster.name
}

output "api_gateway_endpoint" {
  value = "https://${aws_api_gateway_rest_api.tech_challenge_cluster_api_gw.id}.execute-api.us-east-1.amazonaws.com"
  #description = "Endpoint HTTPS global do API Gateway para acessar os recursos da API."
}

# Microservices outputs
output "microservices_namespaces" {
  value = {
    for name, config in var.microservices : name => config.name
  }
  description = "Namespaces created for each microservice"
}

output "microservices_ports" {
  value = {
    for name, config in var.microservices : name => config.port
  }
  description = "Ports configured for each microservice"
}

# LoadBalancer service outputs
output "microservices_loadbalancer_endpoints" {
  value = {
    for name, config in var.microservices : name => {
      service_name = "${config.name}-loadbalancer"
      namespace    = config.name
      port         = config.port
      app_selector = name == "products" ? "tech-product-api" : name == "orders" ? "tech-order-api" : name == "payment" ? "tech-payment-api" : name == "payment-mock" ? "pagamento-mock" : config.name
    }
  }
  description = "LoadBalancer service details for each microservice"
}

output "access_instructions" {
  value       = <<-EOT
    🎉 Your microservices are deployed with LoadBalancer services!
    
    To get the public endpoints, run:
    kubectl get svc -n products-service
    kubectl get svc -n orders-service  
    kubectl get svc -n payment-service
    
    The EXTERNAL-IP column will show your public endpoints.
    
    For the products API:
    - Health: http://[EXTERNAL-IP]:3001/health
    - API: http://[EXTERNAL-IP]:3001/api
    - Products: http://[EXTERNAL-IP]:3001/api/produtos
    - Categories: http://[EXTERNAL-IP]:3001/api/categorias
    
    Note: The LoadBalancer service uses the correct app selector to match your application pods.
  EOT
  description = "Instructions for accessing the deployed microservices"
}

# EKS Cluster outputs
output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.tech_challenge_cluster.endpoint
  description = "EKS Cluster endpoint"
}

output "eks_cluster_certificate_authority" {
  value       = aws_eks_cluster.tech_challenge_cluster.certificate_authority[0].data
  description = "EKS Cluster certificate authority data"
  sensitive   = true
}