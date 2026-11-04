# CloudWatch log group that receives the container logs shipped by Fluent Bit.
# Created here (not by Fluent Bit) so that retention is controlled and costs stay bounded.
resource "aws_cloudwatch_log_group" "containers" {
  name              = "/${var.cluster_name}/containers"
  retention_in_days = 7
}

# Least-privilege policy: write log streams in this one log group only.
data "aws_iam_policy_document" "fluent_bit" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = [
      aws_cloudwatch_log_group.containers.arn,
      "${aws_cloudwatch_log_group.containers.arn}:*",
    ]
  }
}

resource "aws_iam_policy" "fluent_bit" {
  name        = "${var.cluster_name}-fluent-bit"
  description = "Allows Fluent Bit to write container logs to ${aws_cloudwatch_log_group.containers.name}"
  policy      = data.aws_iam_policy_document.fluent_bit.json
}

# IAM role for Fluent Bit.
resource "aws_iam_role" "fluent_bit" {
  name               = "${var.cluster_name}-fluent-bit"
  assume_role_policy = data.aws_iam_policy_document.pod_identity_trust.json
}

resource "aws_iam_role_policy_attachment" "fluent_bit" {
  role       = aws_iam_role.fluent_bit.name
  policy_arn = aws_iam_policy.fluent_bit.arn
}

# Pod Identity association: Fluent Bit may use this role.
# The namespace and service account must match the Helm install in layer 3.
resource "aws_eks_pod_identity_association" "fluent_bit" {
  cluster_name    = module.eks.cluster_name
  namespace       = "logging"
  service_account = "fluent-bit"
  role_arn        = aws_iam_role.fluent_bit.arn
}