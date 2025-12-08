resource "kubernetes_namespace" "karpenter" {
  count = var.create_namespace ? 1 : 0
  
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "karpenter_crd" {
  depends_on = [kubernetes_namespace.karpenter]

  name       = "karpenter-crd"
  chart      = "oci://public.ecr.aws/karpenter/karpenter-crd"
  version    = var.karpenter_version
  namespace  = var.namespace

  timeout    = 600
  wait       = true
}

# Install the main Karpenter chart after CRDs
resource "helm_release" "karpenter" {
  depends_on = [
    helm_release.karpenter_crd,
    kubernetes_namespace.karpenter,
    aws_sqs_queue.karpenter_interruption_queue
  ]

  name       = "karpenter"
  chart      = "oci://public.ecr.aws/karpenter/karpenter"
  version    = var.karpenter_version
  namespace  = var.namespace

  timeout    = 600
  wait       = true

  # v3 syntax: `set` is a list of objects, not blocks
  set = [
    {
      name  = "settings.aws.defaultInstanceProfile"
      value = var.node_instance_profile
    },
    {
      name  = "webhook.tls.generateSelfSignedCerts"
      value = "true"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = var.controller_role_arn
    },
    {
      name  = "settings.clusterName"
      value = var.cluster_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = var.cluster_endpoint
    },
    {
      name  = "controller.resources.requests.cpu"
      value = "500m"
    },
    {
      name  = "controller.resources.requests.memory"
      value = "512Mi"
    },
    {
      name  = "controller.resources.limits.cpu"
      value = "500m"
    },
    {
      name  = "controller.resources.limits.memory"
      value = "512Mi"
    },
    {
      name  = "settings.aws.interruptionQueueName"
      value = aws_sqs_queue.karpenter_interruption_queue.name
    },
  ]
}
