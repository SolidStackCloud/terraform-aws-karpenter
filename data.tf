data "aws_ssm_parameter" "pods_subnet" {
  count = var.solidstack_vpc_module ? 1 : 0
  name  = "/${var.project_name}/pods-subnet-ids"
}