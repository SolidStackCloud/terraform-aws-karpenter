resource "kubectl_manifest" "workers_nodes_karpenter" {
  yaml_body  = <<YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default-karpenter-nodeclass
  namespace: karpenter
spec:
  tags:
    Name: "default-karpenter-nodepool"
  instanceProfile: "${aws_iam_instance_profile.workers_nodes_karpenter.name}"
  amiFamily: "${var.ami_family}"
  amiSelectorTerms:
  - id: "${var.ami_id}"
  securityGroupSelectorTerms:
  - id: "${data.aws_eks_cluster.main.vpc_config.0.cluster_security_group_id}"
  subnetSelectorTerms:
%{for subnet_id in var.solidstack_vpc_module ? data.aws_eks_cluster.main.vpc_config[0].subnet_ids : var.pods_subnets~}
  - id: ${subnet_id}
%{endfor~}
  blockDeviceMappings:
  - deviceName: /dev/xvda
    ebs:
      volumeSize: 100Gi
      volumeType: gp3
      deleteOnTermination: true
      encrypted: true  
YAML
  depends_on = [aws_iam_instance_profile.karpenter, helm_release.karpenter]
}