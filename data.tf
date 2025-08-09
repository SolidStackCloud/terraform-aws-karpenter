data "aws_ssm_parameter" "pods_subnet" {
  count = var.solidstack_vpc_module ? 1 : 0
  name  = "/${var.project_name}/pods-subnet-ids"
}

data "aws_eks_cluster" "main" {
  name = var.solidstack_vpc_module ? "${var.project_name}-cluster" : var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.id
}