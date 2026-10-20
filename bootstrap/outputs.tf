output "state_bucket" {
  description = "Bucket name to set as the TF_STATE_BUCKET repository variable."
  value       = aws_s3_bucket.state.bucket
}

output "plan_role_arn" {
  description = "Role ARN to set as the AWS_PLAN_ROLE_ARN repository variable."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Role ARN to set as the AWS_APPLY_ROLE_ARN repository variable."
  value       = aws_iam_role.apply.arn
}

output "workload_boundary_arn" {
  description = "Permissions boundary that every environment role must use."
  value       = aws_iam_policy.workload_boundary.arn
}

output "github_variables_commands" {
  description = "Ready-to-run gh CLI commands to configure the repository variables."
  value       = <<-EOT
    gh variable set AWS_REGION         --body "${var.aws_region}"
    gh variable set TF_STATE_BUCKET    --body "${aws_s3_bucket.state.bucket}"
    gh variable set AWS_PLAN_ROLE_ARN  --body "${aws_iam_role.plan.arn}"
    gh variable set AWS_APPLY_ROLE_ARN --body "${aws_iam_role.apply.arn}"
  EOT
}
