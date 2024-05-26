provider "aws" {
  region = var.region
}

#Module for creating a new S3 bucket for storing pipeline artifacts
module "s3_artifacts_bucket" {
  source                = "../../modules/s3"
  project_name          = var.project_name
  kms_key_arn           = module.codepipeline_kms.arn
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}

# Resources

# Module for Infrastructure Source code repository
module "codecommit_infrastructure_source_repo" {
  source = "../../modules/codecommit"

  create_new_repo          = var.create_new_repo
  source_repository_name   = var.source_repo_name
  source_repository_branch = var.source_repo_branch
  repo_approvers_arn       = var.repo_approvers_arn
  kms_key_arn              = module.codepipeline_kms.arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }

}

# Module for Infrastructure Validation - CodeBuild
module "codebuild_terraform" {
  depends_on = [
    module.codecommit_infrastructure_source_repo
  ]
  source = "../../modules/codebuild"

  project_name                        = var.project_name
  role_arn                            = module.codepipeline_iam_role.role_arn
  s3_bucket_name                      = module.s3_artifacts_bucket.bucket
  build_projects                      = var.build_projects
  build_project_source                = var.build_project_source
  builder_compute_type                = var.builder_compute_type
  builder_image                       = var.builder_image
  builder_image_pull_credentials_type = var.builder_image_pull_credentials_type
  builder_type                        = var.builder_type
  kms_key_arn                         = module.codepipeline_kms.arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}

module "codepipeline_kms" {
  source                = "../../modules/kms"
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }

}

module "codepipeline_iam_role" {
  source                     = "../../modules/iam-role"
  project_name               = var.project_name
  create_new_role            = var.create_new_role
  codepipeline_iam_role_name = var.create_new_role == true ? "${var.project_name}-codepipeline-role" : var.codepipeline_iam_role_name
  source_repository_name     = var.source_repo_name
  kms_key_arn                = module.codepipeline_kms.arn
  s3_bucket_arn              = module.s3_artifacts_bucket.arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}
# Module for Infrastructure Validate, Plan, Apply and Destroy - CodePipeline
module "codepipeline_terraform" {
  depends_on = [
    module.codebuild_terraform,
    module.s3_artifacts_bucket
  ]
  source = "../../modules/codepipeline"

  project_name          = var.project_name
  source_repo_name      = var.source_repo_name
  source_repo_branch    = var.source_repo_branch
  s3_bucket_name        = module.s3_artifacts_bucket.bucket
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn
  stages                = var.stage_input
  kms_key_arn           = module.codepipeline_kms.arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}


module "batch_fargate" {
  source = "../../modules/batch-fargate-docker"

  app         = var.app
  component   = var.component
  environment = var.environment
  image_tag   = var.image_tag

  docker_source_path = var.docker_source_path
  docker_file_path   = var.docker_file_path
  docker_build_args  = var.docker_build_args

  ecr_lifecycle_image_days = var.ecr_lifecycle_image_days

  ecr_repository_name      = var.ecr_repository_name
  ecr_image_tag_mutability = var.ecr_image_tag_mutability
  ecr_scan_on_push         = var.ecr_scan_on_push
  ecr_encryption_type      = var.ecr_encryption_type

  log_group_retention_in_days = var.log_group_retention_in_days
  log_group_kms_key_arn       = var.log_group_kms_key_arn

  job_definition_propagate_tags        = var.job_definition_propagate_tags
  job_definition_command               = var.job_definition_command
  job_definition_vcpu                  = var.job_definition_vcpu
  job_definition_memory                = var.job_definition_memory
  job_definition_platform_version      = var.job_definition_platform_version
  job_definition_environment_variables = var.job_definition_environment_variables

  compute_resource_security_groups = var.compute_resource_security_groups
  # compute_resource_subnet_ids      = aws_subnet.private_subnets.*.id
  compute_resource_type            = var.compute_resource_type
  compute_resource_max_vcpus       = var.compute_resource_max_vcpus

  job_queue_state                 = var.job_queue_state
  job_queue_scheduling_policy_arn = var.job_queue_scheduling_policy_arn
  job_queue_priority              = var.job_queue_priority

  event_rule_schedule_expression = var.event_rule_schedule_expression
  event_rule_is_enabled          = var.event_rule_is_enabled
}

