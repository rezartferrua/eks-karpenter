output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.project.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.project.endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate"
  value       = aws_eks_cluster.project.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID for the cluster control plane"
  value       = aws_security_group.cluster_sg.id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OIDC identity provider"
  value       = aws_eks_cluster.project.identity[0].oidc[0].issuer
}

output "node_role_arn" {
  description = "ARN of the node role"
  value       = aws_iam_role.node_role.arn
}

output "node_instance_profile_name" {
  description = "Name of the node instance profile"
  value       = aws_iam_instance_profile.node_instance_profile.name
}

