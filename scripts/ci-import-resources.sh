#!/bin/bash

# CI Resource Import Script
# This script automatically imports existing AWS resources into Terraform state
# Designed to run in CI/CD environments without user interaction

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
CLUSTER_NAME="tech_challenge_cluster"

echo "🔧 CI Resource Import Script"
echo "============================"

# Function to check and import EKS cluster
import_eks_cluster() {
    echo "🔍 Checking EKS cluster..."
    if aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION >/dev/null 2>&1; then
        echo "✅ EKS cluster '$CLUSTER_NAME' exists"
        
        # Check if it's already in state
        if terraform state list | grep -q "aws_eks_cluster.tech_challenge_cluster"; then
            echo "ℹ️ EKS cluster already in Terraform state"
        else
            echo "📥 Importing EKS cluster into Terraform state..."
            terraform import aws_eks_cluster.tech_challenge_cluster $CLUSTER_NAME
            echo "✅ EKS cluster imported successfully"
        fi
    else
        echo "❌ EKS cluster '$CLUSTER_NAME' does not exist"
    fi
}

# Function to check and import VPC
import_vpc() {
    echo "🔍 Checking VPC..."
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tech_challenge_vpc" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
    
    if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
        echo "✅ VPC exists with ID: $VPC_ID"
        
        # Check if it's already in state
        if terraform state list | grep -q "aws_vpc.tech_challenge_vpc"; then
            echo "ℹ️ VPC already in Terraform state"
        else
            echo "📥 Importing VPC into Terraform state..."
            terraform import aws_vpc.tech_challenge_vpc $VPC_ID
            echo "✅ VPC imported successfully"
        fi
    else
        echo "❌ VPC does not exist"
    fi
}

# Function to check and import subnets
import_subnets() {
    echo "🔍 Checking subnets..."
    
    # Get VPC ID first
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tech_challenge_vpc" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
    
    if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
        # Check each subnet
        SUBNET_NAMES=("tech_challenge_public_subnet_1" "tech_challenge_public_subnet_2" "tech_challenge_private_subnet_1" "tech_challenge_private_subnet_2")
        
        for subnet_name in "${SUBNET_NAMES[@]}"; do
            SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$subnet_name" --query 'Subnets[0].SubnetId' --output text --region $AWS_REGION)
            
            if [ "$SUBNET_ID" != "None" ] && [ "$SUBNET_ID" != "" ]; then
                echo "✅ Subnet '$subnet_name' exists with ID: $SUBNET_ID"
                
                # Check if it's already in state
                if terraform state list | grep -q "aws_subnet.$subnet_name"; then
                    echo "ℹ️ Subnet '$subnet_name' already in Terraform state"
                else
                    echo "📥 Importing subnet '$subnet_name' into Terraform state..."
                    terraform import aws_subnet.$subnet_name $SUBNET_ID
                    echo "✅ Subnet '$subnet_name' imported successfully"
                fi
            else
                echo "❌ Subnet '$subnet_name' does not exist"
            fi
        done
    else
        echo "❌ Cannot check subnets: VPC does not exist"
    fi
}

# Function to check and import security groups
import_security_groups() {
    echo "🔍 Checking security groups..."
    
    # Get VPC ID first
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tech_challenge_vpc" --query 'Vpcs[0].VpcId' --output text --region $AWS_REGION)
    
    if [ "$VPC_ID" != "None" ] && [ "$VPC_ID" != "" ]; then
        # Check EKS security group
        SG_NAME="SG-tech_challenge_cluster"
        SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text --region $AWS_REGION)
        
        if [ "$SG_ID" != "None" ] && [ "$SG_ID" != "" ]; then
            echo "✅ Security group '$SG_NAME' exists with ID: $SG_ID"
            
            # Check if it's already in state
            if terraform state list | grep -q "aws_security_group.eks_security_group"; then
                echo "ℹ️ EKS security group already in Terraform state"
            else
                echo "📥 Importing EKS security group into Terraform state..."
                terraform import aws_security_group.eks_security_group $SG_ID
                echo "✅ EKS security group imported successfully"
            fi
        else
            echo "❌ EKS security group does not exist"
        fi
        
        # Check ALB security group
        ALB_SG_NAME="SG-ALB-tech_challenge_cluster"
        ALB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=$ALB_SG_NAME" --query 'SecurityGroups[0].GroupId' --output text --region $AWS_REGION)
        
        if [ "$ALB_SG_ID" != "None" ] && [ "$ALB_SG_ID" != "" ]; then
            echo "✅ ALB security group '$ALB_SG_NAME' exists with ID: $ALB_SG_ID"
            
            # Check if it's already in state
            if terraform state list | grep -q "aws_security_group.alb_security_group"; then
                echo "ℹ️ ALB security group already in Terraform state"
            else
                echo "📥 Importing ALB security group into Terraform state..."
                terraform import aws_security_group.alb_security_group $ALB_SG_ID
                echo "✅ ALB security group imported successfully"
            fi
        else
            echo "❌ ALB security group does not exist"
        fi
    else
        echo "❌ Cannot check security groups: VPC does not exist"
    fi
}

# Function to refresh state
refresh_state() {
    echo "🔄 Refreshing Terraform state..."
    terraform refresh -var="aws_region=$AWS_REGION"
    echo "✅ State refreshed"
}

# Main execution
main() {
    echo "🚀 Starting automatic resource import..."
    
    # Import resources in dependency order
    import_vpc
    import_subnets
    import_security_groups
    import_eks_cluster
    
    # Refresh state to sync everything
    refresh_state
    
    echo "✅ Resource import completed!"
    echo "📋 Current resources in state:"
    terraform state list
}

# Check if AWS CLI is configured
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please check AWS credentials."
    exit 1
fi

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Please run 'terraform init' first."
    exit 1
fi

# Run main function
main 