# IAM role for Karpenter controller
resource "aws_iam_role" "karpenter_controller_role" {
  name = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:sub" = "system:serviceaccount:karpenter:karpenter"
          "${trimprefix(module.eks.cluster_oidc_issuer_url, "https://")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# Policy for Karpenter controller
resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "KarpenterControllerPolicy-${var.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:DescribeRegions",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplateVersions",
          "iam:PassRole",
          "iam:ListInstanceProfiles"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:*:*:${var.cluster_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:*:*:cluster/${var.cluster_name}"
      }
    ]
  })
}

# Attach policy to Karpenter controller role
resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}

# IAM role for Karpenter nodes
resource "aws_iam_role" "karpenter_node_role" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Instance profile for Karpenter nodes
resource "aws_iam_instance_profile" "karpenter_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node_role.name
}

# Attach policies to Karpenter node role
resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ])

  policy_arn = each.value
  role       = aws_iam_role.karpenter_node_role.name
}

# Create EKS access entry for Karpenter node role
resource "aws_eks_access_entry" "karpenter_node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node_role.arn
  type          = "EC2_LINUX"

  depends_on = [module.eks]
}

