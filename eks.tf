# EKS Cluster
resource "aws_eks_cluster" "tech_challenge_cluster" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.labrole.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.tech_challenge_public_subnet_1.id,
      aws_subnet.tech_challenge_public_subnet_2.id,
      aws_subnet.tech_challenge_private_subnet_1.id,
      aws_subnet.tech_challenge_private_subnet_2.id
    ]

    security_group_ids = [aws_security_group.eks_security_group.id]
  }

  tags = {
    Name        = "tech_challenge_cluster"
    Environment = var.environment
  }
}

# EKS Node Group
resource "aws_eks_node_group" "tech_challenge_node_group" {
  cluster_name    = var.cluster_name
  node_group_name = "tech_challenge_node_group"
  node_role_arn   = data.aws_iam_role.labrole.arn
  subnet_ids = [
    aws_subnet.tech_challenge_public_subnet_1.id,
    aws_subnet.tech_challenge_public_subnet_2.id,
    aws_subnet.tech_challenge_private_subnet_1.id,
    aws_subnet.tech_challenge_private_subnet_2.id
  ]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  lifecycle {
    prevent_destroy = false
  }

  instance_types = ["t3.medium"]
  disk_size      = 30

  ami_type = "AL2023_x86_64_STANDARD"

  depends_on = [aws_eks_cluster.tech_challenge_cluster]

  tags = {
    Name        = "tech_challenge_node_group"
    Environment = var.environment
  }
}

# Security Group for EKS
resource "aws_security_group" "eks_security_group" {
  vpc_id      = aws_vpc.tech_challenge_vpc.id
  name        = "SG-${var.cluster_name}"
  description = "Allow traffic for EKS Cluster (tech_challenge)"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "eks-security-group"
    Environment = var.environment
  }
}

# Note: OIDC provider creation is skipped for student accounts due to permission restrictions
# The AWS Load Balancer Controller will be installed manually if needed

# Note: IAM roles for AWS Load Balancer Controller are skipped for student accounts
# due to permission restrictions

# Security Group for Application Load Balancer
resource "aws_security_group" "alb_security_group" {
  vpc_id      = aws_vpc.tech_challenge_vpc.id
  name        = "SG-ALB-${var.cluster_name}"
  description = "Security group for Application Load Balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-security-group"
    Environment = var.environment
  }
}