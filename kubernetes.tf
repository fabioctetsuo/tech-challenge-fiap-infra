# Kubernetes Provider configuration
provider "kubernetes" {
  host                   = aws_eks_cluster.tech_challenge_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.tech_challenge_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.tech_challenge_cluster.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.tech_challenge_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.tech_challenge_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.tech_challenge_cluster.token
  }
}

# Data source for EKS cluster auth
data "aws_eks_cluster_auth" "tech_challenge_cluster" {
  name = aws_eks_cluster.tech_challenge_cluster.name
}

# Create namespaces for each microservice
resource "kubernetes_namespace" "microservices" {
  for_each = var.microservices

  metadata {
    name = each.value.name
    labels = {
      name        = each.value.name
      environment = var.environment
    }
  }
}

# Note: AWS Load Balancer Controller installation is skipped for student accounts
# due to OIDC provider permission restrictions
# Load balancers will be created manually or using alternative methods

# Install Metrics Server for HPA support
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  # No version specified - will use latest available
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--kubelet-preferred-address-types=InternalIP"
  }

  depends_on = [aws_eks_cluster.tech_challenge_cluster]
}

# ConfigMap for microservices configuration
resource "kubernetes_config_map" "microservices_config" {
  for_each = var.microservices

  metadata {
    name      = "${each.value.name}-config"
    namespace = each.value.name
  }

  data = {
    "NODE_ENV"     = var.environment
    "SERVICE_PORT" = tostring(each.value.port)
  }

  depends_on = [kubernetes_namespace.microservices]
}

# Create LoadBalancer services for external access (works with student accounts)
resource "kubernetes_service" "microservices_loadbalancer" {
  for_each = var.microservices

  metadata {
    name      = "${each.value.name}-loadbalancer"
    namespace = each.value.name
  }

  spec {
    type = "LoadBalancer"
    selector = {
      # Use the correct app selector that matches the application deployment
      app = each.key == "products" ? "tech-product-api" : each.key == "orders" ? "tech-order-api" : each.key == "payment" ? "tech-payment-api" : each.key == "payment-mock" ? "pagamento-mock" : each.value.name
    }
    port {
      port        = each.value.port
      target_port = each.value.port
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_namespace.microservices]
} 