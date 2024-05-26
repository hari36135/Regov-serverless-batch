

output "codecommit_name" {
  value       = module.codecommit_infrastructure_source_repo.repository_name
  description = "The name of the Codecommit repository"
}

output "codecommit_url" {
  value       = module.codecommit_infrastructure_source_repo.clone_url_http
  description = "The Clone URL of the Codecommit repository"
}

output "codecommit_arn" {
  value       = module.codecommit_infrastructure_source_repo.arn
  description = "The ARN of the Codecommit repository"
}

output "codebuild_name" {
  value       = module.codebuild_terraform.name
  description = "The Name of the Codebuild Project"
}

output "codebuild_arn" {
  value       = module.codebuild_terraform.arn
  description = "The ARN of the Codebuild Project"
}

output "codepipeline_name" {
  value       = module.codepipeline_terraform.name
  description = "The Name of the CodePipeline"
}

output "codepipeline_arn" {
  value       = module.codepipeline_terraform.arn
  description = "The ARN of the CodePipeline"
}

output "iam_arn" {
  value       = module.codepipeline_iam_role.role_arn
  description = "The ARN of the IAM Role used by the CodePipeline"
}

output "kms_arn" {
  value       = module.codepipeline_kms.arn
  description = "The ARN of the KMS key used in the codepipeline"
}

output "s3_arn" {
  value       = module.s3_artifacts_bucket.arn
  description = "The ARN of the S3 Bucket"
}

output "s3_bucket_name" {
  value       = module.s3_artifacts_bucket.bucket
  description = "The Name of the S3 Bucket"
}



output "repository_url" {
  description = "The ECR image URI for deploying lambda"
  value       = module.batch_fargate.repository_url
}

output "repository_arn" {
  description = "The ECR image URI for deploying lambda"
  value       = module.batch_fargate.repository_arn
}

# Log Group
output "aws_cloudwatch_log_group_arn" {
  description = "Batch log group ARN"
  value       = module.batch_fargate.aws_cloudwatch_log_group_arn
}

output "ecs_task_execution_role_arn" {
  description = "ECS task execution role arn"
  value       = module.batch_fargate.ecs_task_execution_role_arn
}

output "batch_job_definition_arn" {
  description = "Batch job definition arn"
  value       = module.batch_fargate.batch_job_definition_arn
}

output "compute_environment_ecs_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the underlying Amazon ECS cluster used by the compute environment."
  value       = module.batch_fargate.compute_environment_ecs_cluster_arn
}

output "compute_environment_arn" {
  description = "Batch compute environment arn"
  value       = module.batch_fargate.compute_environment_arn
}

output "compute_environment_status" {
  description = "Batch compute environment sataus"
  value       = module.batch_fargate.compute_environment_status
}

output "job_queue_arn" {
  description = "Batch job queue arn"
  value       = module.batch_fargate.job_queue_arn

}