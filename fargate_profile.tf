resource "aws_eks_fargate_profile" "karpenter" {
  cluster_name           = data.aws_eks_cluster.main.id
  fargate_profile_name   = "karpenter"
  pod_execution_role_arn = aws_iam_role.karpenter_fargate_profile.arn
  subnet_ids             = data.aws_eks_cluster.main.vpc_config[0].subnet_ids
  selector {
    namespace = "karpenter"
  }
}

resource "aws_iam_role" "karpenter_fargate_profile" {
  name = "karpenter"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.karpenter_fargate_profile.name
}