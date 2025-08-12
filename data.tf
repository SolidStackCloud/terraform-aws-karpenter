data "aws_ssm_parameter" "cluster_name" {
  count = var.solidstack_vpc_module ? 1 : 0
  name  = "/${var.project_name}/cluster-name"
}

data "aws_ssm_parameter" "oidc_arn" {
  count = var.solidstack_vpc_module ? 1 : 0
  name  = "/${var.project_name}/oidc_arn"
}


data "aws_eks_cluster" "main" {
  name = var.solidstack_vpc_module ? data.aws_ssm_parameter.cluster_name[0].value : var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.id
}