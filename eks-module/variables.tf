variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "karpenter_node_role_arn" {
  description = "ARN of the IAM role used by Karpenter provisioned nodes"
  type        = string
  default     = ""
}

variable "admin_user_arn" {
  description = "IAM ARN of the user to be granted access to the EKS cluster"
  type        = string
}
