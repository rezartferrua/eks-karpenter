# Create SQS queue for node interruption handling
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  name                       = "${var.cluster_name}"
  message_retention_seconds  = 300
  visibility_timeout_seconds = 30

  tags = var.tags
}

# Create EventBridge rules for EC2 interruption events
resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  name        = "${var.cluster_name}-karpenter-interruption"
  description = "Forward EC2 instance interruption events to Karpenter SQS queue"

  event_pattern = jsonencode({
    source = ["aws.ec2"],
    detail-type = [
      "EC2 Instance Rebalance Recommendation",
      "EC2 Spot Instance Interruption Warning",
      "EC2 Instance State-change Notification"
    ]
  })

  tags = var.tags
}

# Target for the EventBridge rule - routes to SQS
resource "aws_cloudwatch_event_target" "karpenter_interruption_sqs" {
  rule      = aws_cloudwatch_event_rule.karpenter_interruption.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

# Allow EventBridge to send messages to SQS
resource "aws_sqs_queue_policy" "karpenter_interruption" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.url
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.karpenter_interruption_queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.karpenter_interruption.arn
          }
        }
      }
    ]
  })
}

