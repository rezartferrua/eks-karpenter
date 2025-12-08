variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the EKS nodes"
  type        = string
}

variable "controller_role_arn" {
  description = "ARN of the IAM role for the Karpenter controller"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the EKS cluster is deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for node provisioning"
  type        = list(string)
}

variable "karpenter_version" {
  description = "Version of the Karpenter Helm chart to install"
  type        = string
}

variable "discovery_tag" {
  description = "Tag value used for resource discovery by Karpenter"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for the region"
  type        = list(string)
}

variable "namespace" {
  description = "Kubernetes namespace to deploy Karpenter"
  type        = string
  default     = "karpenter"
}

variable "create_namespace" {
  description = "Whether to create the Karpenter namespace"
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


variable "node_instance_profile" {
  description = "Instance profile for Karpenter nodes"
  type        = string
}

