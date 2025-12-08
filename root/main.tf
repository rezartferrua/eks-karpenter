# 1. VPC Module
module "vpc" {
  source               = "../vpc"
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  project_name         = var.cluster_name
}
# tag subnets properly for Karpenter discovery
resource "aws_ec2_tag" "private_subnet_karpenter_discovery" {
  count       = length(module.vpc.private_subnets)
  resource_id = module.vpc.private_subnets[count.index]
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "cluster_sg_karpenter_discovery" {
  resource_id = module.eks.cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# 2. eks Module
module "eks" {
  source             = "../eks-module"
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  tags               = var.tags

  karpenter_node_role_arn = aws_iam_role.karpenter_node_role.arn
  admin_user_arn          = var.admin_user_arn

  depends_on = [module.vpc]
}

# 3. Karpenter Module (once eks is up)
module "karpenter" {
  source = "../karpenter"

  cluster_name            = var.cluster_name
  cluster_endpoint        = module.eks.cluster_endpoint
  oidc_provider_arn       = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  node_role_arn           = aws_iam_role.karpenter_node_role.arn
  node_instance_profile   = aws_iam_instance_profile.karpenter_instance_profile.name
  controller_role_arn     = aws_iam_role.karpenter_controller_role.arn
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnets
  karpenter_version       = var.karpenter_chart_version
  discovery_tag           = var.cluster_name
  availability_zones      = var.availability_zones

  depends_on = [module.eks]

  providers = {
    kubectl    = kubectl
    kubernetes = kubernetes
    helm       = helm
  }
}


