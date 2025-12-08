# EKS Cluster with Karpenter for Autoscaling

This repository contains Terraform code to deploy an AWS EKS cluster with Karpenter autoscaling. The infrastructure is designed to leverage both x86 (AMD64) and ARM64 (Graviton) instances, as well as Spot instances for better price/performance ratio.

## Project Structure

```
.
├── eks-module          # EKS cluster creation module
│   ├── eks.tf          # Main EKS cluster configuration
│   ├── iam.tf          # IAM roles and policies for EKS
│   ├── output.tf       # Module outputs
│   └── variables.tf    # Module variables
├── karpenter           # Karpenter autoscaling module
│   ├── interruption-handling.tf  # SQS and EventBridge for spot instance handling
│   ├── karpenter.tf    # Karpenter Helm deployment
│   ├── outputs.tf      # Module outputs
│   ├── providers.tf    # Provider configurations
│   └── variables.tf    # Module variables
├── root                # Main deployment directory
│   ├── karpenter-iam.tf # IAM roles for Karpenter
│   ├── main.tf         # Main Terraform configuration
│   ├── output.tf       # Output values
│   ├── provider.tf     # Provider configurations
│   └── variables.tf    # Variable definitions
└── vpc                 # VPC module
    ├── igw.tf          # Internet Gateway
    ├── nat.tf          # NAT Gateway
    ├── output.tf       # Module outputs
    ├── routetable.tf   # Route tables for subnets
    ├── variables.tf    # Module variables
    └── vpc.tf          # VPC and subnet definitions
```

## Key Components

### VPC Configuration
- Dedicated VPC with CIDR range `10.0.0.0/16` (ensure this range doesn't overlap with other VPCs in your account or with on-premises networks if using VPN/Direct Connect)
- Public subnets in multiple AZs with Internet Gateway
- Private subnets in multiple AZs with NAT Gateway
- Proper tagging for Kubernetes & Karpenter discovery

### EKS Cluster
- EKS v1.34 cluster deployed in private subnets
- OIDC provider configuration for IAM roles
- Initial node group with `c7i-flex.large` instances (free on new aws accounts)
- Security groups for proper cluster communication

### Karpenter Autoscaler
- Deployed via Helm charts v4.0.0
- NodePool configurations for both ARM64 and AMD64
- Spot instance interrupt handling via SQS queue
- EventBridge rules for EC2 interruption events

## Architecture

The infrastructure includes:

- Amazon EKS Cluster (v1.34)
- Dedicated VPC with public and private subnets across multiple AZs
- Karpenter autoscaler for dynamic node provisioning (v1.8.2)
- Support for both x86 (AMD64) and ARM64 (Graviton) instances
- Support for both Spot and On-Demand instances
- Spot instance interruption handling via SQS and EventBridge
- IAM roles with least privilege principles
- Security groups configured for proper cluster communication

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform v1.0.0+
- kubectl
- Helm v3+

## Getting Started

### Clone this repository:

```bash
git clone <repository-url>
cd eks-karpenter
```

### Initialize Terraform:

```bash
terraform init
```

### Environment Configuration

Configure variables in eks-module/variables.tf

`
### Review and apply the Terraform plan:

```bash
terraform plan 
terraform apply 

### Configure kubectl to interact with your new cluster:

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

## Using the Cluster

### Running Workloads on x86 (AMD64) Instances

```bash
kubectl apply -f < raw-url-of-root/YAML/x86-app.yaml >
```

### Running Workloads on ARM64 (Graviton) Instances

```bash
kubectl apply -f < raw-url-of-root/YAML/arm64-app.yaml >
```

### Using Spot Instances

```bash
kubectl apply -f < raw-url-of-root/YAML/spot_simple_node_selector.yaml >
```

## Troubleshooting & Debugging

A quick reference for common issues with Karpenter and EKS.

### 🛑 Karpenter Issues

**Karpenter pods in CrashLoopBackOff**
- Check logs: `kubectl logs -n karpenter <pod-name> -c controller`
- Ensure `CLUSTER_NAME` and `CLUSTER_ENDPOINT` are correctly configured in Helm values

**Nodes not joining the cluster**
- Check node status: `kubectl get nodes` and `kubectl get nodeclaims`
- Verify security group rules to ensure proper communication between control plane and nodes
- Ensure cluster endpoint is accessible from the VPC
- Ensure proper AMI referenced (specific EKS AMIs with appropriately boot strapped)

**ARM64 pods in Pending state**
- Verify NodePool configuration allows ARM64 architecture
- Ensure proper ARM64 AMIs are configured in EC2NodeClass
- Create dedicated NodePool and EC2NodeClass for ARM64 workloads if needed

### 🔍 Quick Debugging Commands

```bash
# Check Karpenter logs
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -c controller

# Monitor node provisioning
kubectl get nodes -w
kubectl get nodeclaims

# Test Karpenter with sample workload
kubectl apply -f inflate.yaml
kubectl scale deployment inflate --replicas=5
```

For more detailed troubleshooting, refer to the [Karpenter documentation](https://karpenter.sh/docs/troubleshooting/).

## Cleanup

To destroy all resources:

```bash
terraform destroy 
```

## Additional Resources

- [Karpenter Documentation](https://karpenter.sh/docs/)
- [EKS Workshop](https://www.eksworkshop.com/)
- [AWS Graviton Documentation](https://aws.amazon.com/ec2/graviton/)


# eks-karpenter
