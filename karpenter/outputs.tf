output "karpenter_namespace" {
  description = "Namespace where Karpenter is deployed"
  value       = var.namespace
}

output "karpenter_release_name" {
  description = "Name of the Karpenter Helm release"
  value       = helm_release.karpenter.name
}

output "karpenter_provisioner_name" {
  description = "Name of the default Karpenter provisioner"
  value       = "default"
}

output "karpenter_node_instance_profile" {
  description = "Instance profile used by Karpenter nodes"
  value       = var.node_instance_profile
}


output "interruption_queue_url" {
  description = "URL of the SQS queue for node interruption events"
  value       = aws_sqs_queue.karpenter_interruption_queue.url
}

output "interruption_queue_name" {
  description = "Name of the SQS queue for node interruption events"
  value       = aws_sqs_queue.karpenter_interruption_queue.name
}

