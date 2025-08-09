resource "kubectl_manifest" "nodepool" {
    yaml_body = <<YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: "default-karpenter--nodepool"
  namespace: karpenter
spec:
  disruption:
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: ${var.nodepool_consolidate_after}
  template:
    metadata:
      labels:
        workload: karpenter
        role: "default-karpenter--nodepool"
        karpenter: managed
    spec:
      requirements:
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values:
%{for family in var.nodepool_instance_families~}
            - ${family}
%{endfor}
        - key: karpenter.sh/capacity-type
          operator: In
          values:
%{for capacity_type in var.nodepool_capacity_types~}
            - ${capacity_type}
%{endfor}
        - key: karpenter.k8s.aws/instance-size
          operator: In
          values:
%{for size in var.nodepool_instance_sizes~}
            - ${size}
%{endfor}
      nodeClassRef:
        group: karpenter.k8s.aws
        kind: EC2NodeClass
        name: "default-karpenter-nodeclass"
YAML
  depends_on = [ aws_iam_instance_profile.karpenter, helm_release.karpenter ]
}
