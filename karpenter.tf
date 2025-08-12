resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  name             = "karpenter"
  create_namespace = true
  chart            = "oci://public.ecr.aws/karpenter/karpenter"
  version          = var.karpenter_version
  force_update     = true
  set = [
    {
      name  = "settings.clusterName"
      value = data.aws_eks_cluster.main.id
    },
    {
      name  = "settings.clusterEndpoint"
      value = data.aws_eks_cluster.main.endpoint
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.karpenter.arn
    },
    {
      name  = "settings.defaultInstanceProfile"
      value = aws_iam_instance_profile.workers_nodes_karpenter.name
    },
    {
      name  = "settings.interruptionQueueName"
      value = aws_sqs_queue.karpenter.name
    },
    {
      name  = "settings.spotToSpotConsolidation"
      value = true
    }
  ]

  depends_on = [aws_eks_fargate_profile.karpenter]
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "karpenter"
  role = aws_iam_role.karpenter.name
}

#### Controller IAM

data "aws_iam_policy_document" "karpenter" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      identifiers = [data.aws_ssm_parameter.oidc_arn[0].value]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "karpenter" {
  assume_role_policy = data.aws_iam_policy_document.karpenter.json
  name               = "${var.project_name}-karpenter"
}


data "aws_iam_policy_document" "karpenter_policy" {
  version = "2012-10-17"

  statement {

    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:CreateTags",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSpotPriceHistory",
      "pricing:GetProducts",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
      "ssm:GetParameter",
      "iam:PassRole",
      "sqs:*"
    ]

    resources = [
      "*"
    ]

  }
}

resource "aws_iam_policy" "karpenter" {
  name   = "${var.project_name}-karpenter"
  path   = "/"
  policy = data.aws_iam_policy_document.karpenter_policy.json
}


resource "aws_iam_policy_attachment" "karpenter" {
  name = "karpenter"
  roles = [
    aws_iam_role.karpenter.name
  ]

  policy_arn = aws_iam_policy.karpenter.arn
}