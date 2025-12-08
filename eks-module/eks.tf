# Create EKS Cluster
resource "aws_eks_cluster" "project" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.cluster_sg.id]
  }

  access_config {
    authentication_mode = "API"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]

  tags = var.tags
}

# Create Security Group for EKS cluster
resource "aws_security_group" "cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name                     = "${var.cluster_name}-cluster-sg"
      "karpenter.sh/discovery" = var.cluster_name
    }
  )
}

resource "aws_security_group_rule" "cluster_to_node" {
  security_group_id        = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = aws_security_group.cluster_sg.id # existing SG
  description              = "Allow control plane to communicate with nodes"
}

# Create initial node group (minimal) just for the control plane
resource "aws_eks_node_group" "initial" {
  cluster_name    = aws_eks_cluster.project.name
  node_group_name = "${var.cluster_name}-initial"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["c7i-flex.large"]
  
  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_cluster.project,
    aws_iam_role_policy_attachment.node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.ecr_read_policy,
    aws_iam_role_policy_attachment.ssm_policy
  ]

  # Let Karpenter handle additional nodes, project is just to get the cluster running
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  tags = var.tags
}

# Create IAM OIDC provider for the cluster
data "tls_certificate" "eks" {
  url = aws_eks_cluster.project.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.project.identity[0].oidc[0].issuer
}

# EKS Access Entry
resource "aws_eks_access_entry" "entry" {
  cluster_name  = aws_eks_cluster.project.name
  principal_arn = var.admin_user_arn
  type          = "STANDARD"

  depends_on = [
    aws_eks_cluster.project
  ]
}

# Access Policy Association
resource "aws_eks_access_policy_association" "policy_association" {
  cluster_name  = aws_eks_cluster.project.name
  security_group_id        = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.entry
  ]
}

# Get the cluster security group ID 
resource "aws_security_group_rule" "cluster_to_nodes" {
  description              = "Allow control plane to communicate with nodes kubelet"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  type                     = "egress"
}

# Allow nodes to communicate with control plane API
resource "aws_security_group_rule" "nodes_to_cluster" {
  description              = "Allow nodes to communicate with API server"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  type                     = "ingress"
}

# Inbound rule on the node security group to allow control plane communication
resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.cluster_sg.id
  type                     = "ingress"
}

# Allow control plane to access kubelet API on nodes
resource "aws_security_group_rule" "cluster_ingress_kubelet" {
  description              = "Allow control plane to access kubelet API"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_sg.id
  source_security_group_id = aws_eks_cluster.project.vpc_config[0].cluster_security_group_id
  type                     = "ingress"
}

# Node-to-node communication for your custom security group
resource "aws_security_group_rule" "node_to_node" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  security_group_id        = aws_security_group.cluster_sg.id
  source_security_group_id = aws_security_group.cluster_sg.id
  type                     = "ingress"
}