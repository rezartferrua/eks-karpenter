output "cluster_name" {
  description = "eks cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for eks control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID for the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "karpenter_controller_role_arn" {
  description = "ARN of the Karpenter controller IAM role"
  value       = aws_iam_role.karpenter_controller_role.arn
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the eks cluster for the OIDC identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "karpenter_node_pools" {
  description = "Karpenter node pools configured"
  value = {
    "x86-spot"          = "AMD64 Architecture with Spot pricing"
    "graviton-spot"     = "ARM64 Architecture with Spot pricing"
    "x86-ondemand"      = "AMD64 Architecture with On-Demand pricing"
    "graviton-ondemand" = "ARM64 Architecture with On-Demand pricing"
  }
}

output "karpenter_node_instance_profile" {
  description = "Instance profile for Karpenter nodes"
  value       = aws_iam_instance_profile.karpenter_instance_profile.name
}

output "karpenter_node_role_arn" {
  description = "ARN of the IAM role used by Karpenter provisioned nodes"
  value       = aws_iam_role.karpenter_node_role.arn
}

