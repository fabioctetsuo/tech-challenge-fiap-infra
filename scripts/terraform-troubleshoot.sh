#!/bin/bash

# Terraform Troubleshooting Script
# This script helps resolve common Terraform issues

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME="tech_challenge_cluster"

echo "🔧 Terraform Troubleshooting Script"
echo "=================================="

# Function to check if EKS cluster exists
check_eks_cluster() {
    echo "🔍 Checking if EKS cluster exists..."
    if aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION >/dev/null 2>&1; then
        echo "✅ EKS cluster '$CLUSTER_NAME' exists"
        return 0
    else
        echo "❌ EKS cluster '$CLUSTER_NAME' does not exist"
        return 1
    fi
}

# Function to check if VPC exists
check_vpc() {
    echo "🔍 Checking if VPC exists..."
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tech_challenge_vpc" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
    if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
        echo "✅ VPC exists with ID: $VPC_ID"
        return 0
    else
        echo "❌ VPC does not exist"
        return 1
    fi
}

# Function to import EKS cluster
import_eks_cluster() {
    echo "📥 Importing EKS cluster into Terraform state..."
    terraform import aws_eks_cluster.tech_challenge_cluster $CLUSTER_NAME
    echo "✅ EKS cluster imported successfully"
}

# Function to import VPC
import_vpc() {
    echo "📥 Importing VPC into Terraform state..."
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tech_challenge_vpc" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
    terraform import aws_vpc.tech_challenge_vpc $VPC_ID
    echo "✅ VPC imported successfully"
}

# Function to clean up state
cleanup_state() {
    echo "🧹 Cleaning up Terraform state..."
    echo "⚠️ This will remove resources from state but NOT delete them from AWS"
    echo "📋 Current resources in state:"
    terraform state list
    
    read -p "Do you want to remove all resources from state? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️ Removing all resources from state..."
        terraform state list | xargs -I {} terraform state rm {}
        echo "✅ State cleaned up"
    else
        echo "❌ State cleanup cancelled"
    fi
}

# Function to refresh state
refresh_state() {
    echo "🔄 Refreshing Terraform state..."
    terraform refresh -var="aws_region=$AWS_REGION"
    echo "✅ State refreshed"
}

# Function to show plan
show_plan() {
    echo "📋 Running Terraform plan..."
    terraform plan -var="aws_region=$AWS_REGION"
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1) Check existing resources"
    echo "2) Import EKS cluster"
    echo "3) Import VPC"
    echo "4) Refresh state"
    echo "5) Clean up state (remove all resources from state)"
    echo "6) Show plan"
    echo "7) Exit"
    echo ""
}

# Main execution
main() {
    while true; do
        show_menu
        read -p "Enter your choice (1-7): " choice
        
        case $choice in
            1)
                echo "🔍 Checking existing resources..."
                check_eks_cluster
                check_vpc
                ;;
            2)
                if check_eks_cluster; then
                    import_eks_cluster
                else
                    echo "❌ Cannot import: EKS cluster does not exist"
                fi
                ;;
            3)
                if check_vpc; then
                    import_vpc
                else
                    echo "❌ Cannot import: VPC does not exist"
                fi
                ;;
            4)
                refresh_state
                ;;
            5)
                cleanup_state
                ;;
            6)
                show_plan
                ;;
            7)
                echo "👋 Goodbye!"
                exit 0
                ;;
            *)
                echo "❌ Invalid option. Please choose 1-7."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Please run 'terraform init' first."
    exit 1
fi

# Run main function
main 