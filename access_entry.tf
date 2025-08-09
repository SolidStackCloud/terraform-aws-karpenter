resource "aws_eks_access_entry" "workers_nodes_karpenter" {
  cluster_name  = data.aws_eks_cluster.main.id
  principal_arn = aws_iam_role.workers_nodes_karpenter.arn
  type          = "EC2_LINUX"
}