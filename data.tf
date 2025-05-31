data "aws_eks_cluster_auth" "tech_challenge_cluster_auth" {
  name = aws_eks_cluster.tech_challenge_cluster.name
}

data "aws_iam_role" "labrole" {
  name = "LabRole"
}