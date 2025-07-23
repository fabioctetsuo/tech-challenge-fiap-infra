# Tech Challenge FIAP - Microservices Infrastructure

This repository contains the Terraform code to provision and manage the AWS infrastructure for the Tech Challenge FIAP project, supporting a microservices architecture with 3 NestJS microservices running on EKS (Elastic Kubernetes Service).

## Phase 3 - Delivering 03/06/2025

- [YouTube demo](https://www.youtube.com/watch?v=BylRL1trhcA)

## Overview

- **Cloud Provider:** AWS
- **Architecture:** Microservices on EKS
- **Main Components:**
  - VPC with public and private subnets
  - EKS Cluster and Node Group
  - AWS Load Balancer Controller
  - Application Load Balancer (ALB) for ingress
  - API Gateway
  - NAT Gateway and Internet Gateway
  - AWS Secrets Manager for sensitive data
  - Separate namespaces for each microservice

## Microservices Architecture

The infrastructure supports 3 microservices:

1. **Products Service** (`products-service`) - Port 3001
2. **Orders Service** (`orders-service`) - Port 3002  
3. **Payment Service** (`payment-service`) - Port 3003

Each microservice runs in its own Kubernetes namespace with:
- Dedicated ALB ingress rules
- Horizontal Pod Autoscaling
- Health checks and monitoring
- Resource limits and requests

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.2.0
- AWS account and credentials with permissions to create EKS, VPC, IAM, and related resources
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for interacting with EKS)
- [helm](https://helm.sh/docs/intro/install/) (for installing Kubernetes charts)
- (Optional) [direnv](https://direnv.net/) or similar for environment variable management

## Project Structure

```
tech-challenge-fiap-infra/
├── eks.tf                           # EKS cluster and node group resources
├── networks.tf                      # VPC, subnets, gateways, and routing
├── kubernetes.tf                    # Kubernetes resources and Helm charts
├── providers.tf                     # Provider configuration
├── variables.tf                     # Input variables including microservices config
├── outputs.tf                       # Output values
├── secrets.tf                       # Secrets Manager resources
├── data.tf                          # Data sources (IAM roles, EKS auth)
├── terraform.sh                     # Helper script for Terraform commands
├── scripts/                         # Helper scripts
│   └── terraform-troubleshoot.sh    # Troubleshooting script for common issues
├── policies/                        # IAM policies
│   └── aws-load-balancer-controller-policy.json
├── k8s-templates/                   # Kubernetes deployment templates
│   └── microservice-deployment-template.yaml
├── .github/workflows/               # CI/CD workflows (deploy, destroy)
└── README.md                        # This file
```

## Usage

1. **Clone the repository:**

   ```sh
   git clone <repo-url>
   cd tech-challenge-fiap-infra
   ```

2. **Configure AWS credentials:**
   Ensure your AWS credentials are set in your environment (e.g., via `~/.aws/credentials` or environment variables).

3. **(Optional) Create a `.env` file:**
   This file should define at least `AWS_REGION` (default: `us-east-1`).

4. **Initialize Terraform:**

   ```sh
   terraform init
   ```
   
   **Note:** The Terraform backend (S3 bucket and DynamoDB table) is automatically created during the first deployment. No manual setup required!

**Backend Resources:**
- S3 bucket: `tech-challenge-fiap-terraform-state-2025` (for state storage)
- DynamoDB table: `tech-challenge-fiap-terraform-locks` (for state locking)

6. **Plan the deployment:**

   ```sh
   terraform plan -var "aws_region=<your-region>"
   ```

7. **Apply the deployment:**

   ```sh
   terraform apply -var "aws_region=<your-region>"
   ```

   Or use the helper script:

   ```sh
   ./terraform.sh apply
   ```

5. **Plan the deployment:**

   ```sh
   terraform plan -var "aws_region=<your-region>"
   ```

6. **Apply the deployment:**

   ```sh
   terraform apply -var "aws_region=<your-region>"
   ```

   Or use the helper script:

   ```sh
   ./terraform.sh apply
   ```

7. **Destroy the infrastructure:**
   ```sh
   terraform destroy -var "aws_region=<your-region>"
   ```
   Or use the helper script:
   ```sh
   ./terraform.sh destroy
   ```

## Variables

| Name         | Description             | Type   | Default                  |
| ------------ | ----------------------- | ------ | ------------------------ |
| aws_region   | AWS region              | string | "us-east-1"              |
| cluster_name | Name of the EKS Cluster | string | "tech_challenge_cluster" |
| environment  | Environment name        | string | "development"            |
| domain_name  | Domain for ingress      | string | "tech-challenge.local"   |
| microservices| Microservices config    | map    | See variables.tf         |

## Microservices Configuration

The `microservices` variable defines the configuration for each service:

```hcl
microservices = {
  products = {
    name        = "products-service"
    port        = 3001
    replicas    = 2
    cpu_limit   = "500m"
    memory_limit = "512Mi"
    cpu_request = "250m"
    memory_request = "256Mi"
  }
  orders = {
    name        = "orders-service"
    port        = 3002
    replicas    = 2
    cpu_limit   = "500m"
    memory_limit = "512Mi"
    cpu_request = "250m"
    memory_request = "256Mi"
  }
  payment = {
    name        = "payment-service"
    port        = 3003
    replicas    = 2
    cpu_limit   = "500m"
    memory_limit = "512Mi"
    cpu_request = "250m"
    memory_request = "256Mi"
  }
}
```

## Deploying Individual Microservices

Each microservice should be deployed to its own repository. Use the template in `k8s-templates/microservice-deployment-template.yaml` as a starting point.

### Steps for deploying a microservice:

1. **Build and push your Docker image** to a container registry
2. **Update the deployment template** with your service-specific values:
   - Replace `SERVICE_NAME` with your service name
   - Replace `SERVICE_PORT` with your service port
   - Update the image reference
   - Add service-specific environment variables
3. **Apply the deployment** to the EKS cluster:

   ```sh
   kubectl apply -f k8s/deployment.yaml
   ```

### Example for Products Service:

```yaml
# Replace SERVICE_NAME with "products-service"
# Replace SERVICE_PORT with "3001"
# Update image to your registry/products-service:latest
```

## Load Balancing & Ingress

The infrastructure uses **AWS Application Load Balancer (ALB)** for ingress traffic:

- **Single ALB** handles traffic for all 3 microservices
- **Host-based routing**: `service-name.tech-challenge.local`
- **Health checks** at `/health` endpoint
- **Cost-effective** - only one load balancer for all services

### ALB Features:
- ✅ **Host-based routing** - Each service gets its own subdomain
- ✅ **Health checks** - Automatic health monitoring
- ✅ **SSL/TLS support** - Can be configured for HTTPS
- ✅ **AWS-native** - Better integration with AWS services
- ✅ **Cost-effective** - Single load balancer for all services

### Service Endpoints:
- `products-service.tech-challenge.local` → Products Service (port 3001)
- `orders-service.tech-challenge.local` → Orders Service (port 3002)
- `payment-service.tech-challenge.local` → Payment Service (port 3003)

## Troubleshooting

### Common Terraform Issues

If you encounter errors about resources already existing (e.g., `tech_challenge_cluster`), use the troubleshooting script:

```bash
./scripts/terraform-troubleshoot.sh
```

This script provides options to:
- **Check existing resources** in AWS
- **Import existing resources** into Terraform state
- **Refresh state** to sync with actual AWS resources
- **Clean up state** (remove resources from state without deleting from AWS)
- **Show plan** to see what changes would be made

### Manual Troubleshooting Steps

1. **Check if resources exist in AWS:**
   ```bash
   aws eks describe-cluster --name tech_challenge_cluster --region us-east-1
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tech_challenge_vpc" --region us-east-1
   ```

2. **Import existing resources:**
   ```bash
   # Import EKS cluster
   terraform import aws_eks_cluster.tech_challenge_cluster tech_challenge_cluster
   
   # Import VPC (replace vpc-12345678 with actual VPC ID)
   terraform import aws_vpc.tech_challenge_vpc vpc-12345678
   ```

3. **Refresh state:**
   ```bash
   terraform refresh -var="aws_region=us-east-1"
   ```

4. **Check state:**
   ```bash
   terraform state list
   terraform state show aws_eks_cluster.tech_challenge_cluster
   ```

### Destroy Issues in CI/CD

**Problem:** Destroy workflow runs but doesn't actually destroy resources.

**Root Cause:** Terraform was using local state instead of a persistent backend, so each CI/CD run started with a clean state and couldn't see existing resources.

**Solution:** 
- ✅ **Fixed:** Added S3 backend for state management (`tech-challenge-terraform-state` bucket)
- ✅ **Fixed:** Added DynamoDB table for state locking (`tech-challenge-terraform-locks`)
- ✅ **Fixed:** Updated workflows to properly initialize the backend
- ✅ **Fixed:** Added verification steps to confirm destruction

**Prevention:** Always use a remote backend (S3) for CI/CD environments.

### Why Not Destroy and Recreate?

Destroying and recreating infrastructure is **not recommended** because:
- ❌ **Data loss** - All data in databases, logs, etc. is lost
- ❌ **Service downtime** - Applications become unavailable
- ❌ **Costly** - Recreating resources takes time and money
- ❌ **Complex dependencies** - Some resources have dependencies that make recreation difficult

Instead, use **Terraform's state management** to handle existing resources properly.

## Outputs

| Name                           | Description                 |
| ------------------------------ | --------------------------- |
| vpc_id                         | The ID of the created VPC   |
| eks_cluster_name              | The name of the EKS cluster |
| api_gateway_endpoint          | API Gateway endpoint URL    |
| microservices_namespaces      | Namespaces for each service |
| microservices_ports           | Ports for each service      |
| microservices_ingress_hosts   | ALB Ingress hosts for services  |
| aws_load_balancer_controller  | AWS Load Balancer Controller name  |
| load_balancer_controller_role_arn | ALB Controller IAM role ARN |

## CI/CD

This repository includes GitHub Actions workflows for automated deployment and destruction:

- **Deploy:** `.github/workflows/deploy.yml` runs on push to `main` and on manual dispatch. It automatically sets up the Terraform backend (S3 bucket and DynamoDB table) if needed, then initializes Terraform, plans, and applies the infrastructure.
- **Destroy:** `.github/workflows/destroy.yml` can be triggered manually to destroy all resources with proper state management.
- **Validate:** `.github/workflows/validate.yml` runs on PRs to validate infrastructure changes.

All workflows require AWS credentials to be set as GitHub secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) and the region as a variable (`AWS_REGION`).

### Automated Backend Management
- ✅ **No manual setup** - Backend resources are created automatically
- ✅ **Self-healing** - Missing resources are recreated if needed
- ✅ **Idempotent** - Safe to run multiple times
- ✅ **State persistence** - Terraform state is stored in S3 between runs

## Security Notes

- Sensitive files such as `.tfvars` and state files are excluded from version control via `.gitignore`.
- Secrets are managed using AWS Secrets Manager.
- Each microservice runs in its own namespace for isolation.
- Never commit sensitive values or credentials to the repository.

## Monitoring and Scaling

- **Metrics Server** is installed for resource monitoring
- **Horizontal Pod Autoscalers** are configured for each service
- **Health checks** are configured for liveness and readiness probes
- **Resource limits** are set to prevent resource exhaustion
- **AWS ALB health checks** monitor service availability

## License

This project is for educational purposes. Please adapt and review for production use.
