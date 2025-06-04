# Tech Challenge FIAP - Base Infrastructure

This repository contains the Terraform code to provision and manage the AWS infrastructure for the Tech Challenge FIAP project, including an EKS (Elastic Kubernetes Service) cluster, VPC networking, API Gateway, and secret management.

## Phase 3 - Delivering 03/06/2025

- [YouTube demo](https://www.youtube.com/watch?v=BylRL1trhcA)

## Overview

- **Cloud Provider:** AWS
- **Main Components:**
  - VPC with public and private subnets
  - EKS Cluster and Node Group
  - API Gateway
  - NAT Gateway and Internet Gateway
  - AWS Secrets Manager for sensitive data

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.2.0
- AWS account and credentials with permissions to create EKS, VPC, IAM, and related resources
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (for interacting with EKS)
- (Optional) [direnv](https://direnv.net/) or similar for environment variable management

## Project Structure

```
tech-challenge-fiap-infra/
├── eks.tf                # EKS cluster and node group resources
├── networks.tf           # VPC, subnets, gateways, and routing
├── providers.tf          # Provider configuration
├── variables.tf          # Input variables
├── outputs.tf            # Output values
├── secrets.tf            # Secrets Manager resources
├── data.tf               # Data sources (IAM roles, EKS auth)
├── terraform.sh          # Helper script for Terraform commands
├── .github/workflows/    # CI/CD workflows (deploy, destroy)
└── ...
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

## Outputs

| Name                 | Description                 |
| -------------------- | --------------------------- |
| vpc_id               | The ID of the created VPC   |
| eks_cluster_name     | The name of the EKS cluster |
| api_gateway_endpoint | API Gateway endpoint URL    |

## CI/CD

This repository includes GitHub Actions workflows for automated deployment and destruction:

- **Deploy:** `.github/workflows/deploy.yml` runs on push to `main` and on manual dispatch. It initializes Terraform, plans, and applies the infrastructure.
- **Destroy:** `.github/workflows/destroy.yml` can be triggered manually to destroy all resources.

Both workflows require AWS credentials to be set as GitHub secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`) and the region as a variable (`AWS_REGION`).

## Security Notes

- Sensitive files such as `.tfvars` and state files are excluded from version control via `.gitignore`.
- Secrets (e.g., JWT keys) are managed using AWS Secrets Manager.
- Never commit sensitive values or credentials to the repository.

## License

This project is for educational purposes. Please adapt and review for production use.
