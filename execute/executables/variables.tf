# AWS region
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  description = "Unique name for this project"
  type        = string
}

variable "create_new_repo" {
  description = "Whether to create a new repository. Values are true or false. Defaulted to true always."
  type        = bool
  default     = true
}

variable "create_new_role" {
  description = "Whether to create a new IAM Role. Values are true or false. Defaulted to true always."
  type        = bool
  default     = true
}

variable "codepipeline_iam_role_name" {
  description = "Name of the IAM role to be used by the Codepipeline"
  type        = string
  default     = "codepipeline-role"
}

variable "source_repo_name" {
  description = "Source repo name of the CodeCommit repository"
  type        = string
}

variable "source_repo_branch" {
  description = "Default branch in the Source repo for which CodePipeline needs to be configured"
  type        = string
}

variable "repo_approvers_arn" {
  description = "ARN or ARN pattern for the IAM User/Role/Group that can be used for approving Pull Requests"
  type        = string
}

variable "environment" {
  description = "Environment in which the script is run. Eg: dev, prod, etc"
  type        = string
}

variable "stage_input" {
  description = "Tags to be attached to the CodePipeline"
  type        = list(map(any))
}

variable "build_projects" {
  description = "Tags to be attached to the CodePipeline"
  type        = list(string)
}

variable "builder_compute_type" {
  description = "Relative path to the Apply and Destroy build spec file"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "builder_image" {
  description = "Docker Image to be used by codebuild"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
}

variable "builder_type" {
  description = "Type of codebuild run environment"
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "builder_image_pull_credentials_type" {
  description = "Image pull credentials type used by codebuild project"
  type        = string
  default     = "CODEBUILD"
}

variable "build_project_source" {
  description = "aws/codebuild/standard:4.0"
  type        = string
  default     = "CODEPIPELINE"
}

# vpc cidr
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.3.0.0/16"
}

# public subnet cidrs
variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.3.0.0/20", "10.3.16.0/20", "10.3.32.0/20"]
}
#  private subnet cidrs
variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.3.48.0/20", "10.3.64.0/20", "10.3.80.0/20"]
}

# Availability zone preference
variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
}
variable "app" {
  description = "Value for the app tag"
  type        = string
  default     = "mooon-lander"
}

variable "component" {
  description = "Value for component tag"
  type        = string
  default     = "import-moon-lander"
}

# variable "environment" {
#   description = "Environment to be used e.g dev/prod/stage "
#   type        = string
#   default     = "dev"
# }

variable "docker_source_path" {
  description = "Path to folder containing application code"
  type        = string
  default     = null
}

variable "docker_file_path" {
  description = "Path to Dockerfile in source package"
  type        = string
  default     = "Dockerfile"
}

variable "docker_build_args" {
  description = "A map of Docker build arguments."
  type        = map(string)
  default     = {}
}

variable "ecr_lifecycle_image_days" {
  description = "The value is the maximum number of images that you want to retain in your repository."
  type        = number
  default     = 8
}

variable "image_tag" {
  description = "Image tag to use. If not provided date will be used"
  type        = string
  default     = "latest"
}

variable "ecr_repository_name" {
  description = "Name of the ECR registory to use"
  type        = string
}

variable "ecr_image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE` or `IMMUTABLE`"
  type        = string
  default     = "IMMUTABLE"
}

variable "ecr_scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository"
  type        = bool
  default     = true
}

variable "ecr_encryption_type" {
  description = "The encryption type to use for the repository. Valid values are AES256 or KMS"
  type        = string
  default     = "AES256"
}

variable "log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = 30
}

variable "log_group_kms_key_arn" {
  description = "The ARN of the KMS Key to use when encrypting log data."
  type        = string
  default     = null
}

variable "job_definition_propagate_tags" {
  description = "Specifies whether to propagate the tags from the job definition to the corresponding Amazon ECS task."
  type        = bool
  default     = false
}

variable "job_definition_command" {
  description = "The command that's passed to the container."
  type        = list(any)
}

variable "job_definition_vcpu" {
  description = "Amount of cpu to assign to a container. Possible values 0.25, 0.5, 1, 2, 4"
  type        = number
  default     = 0.25
}

variable "job_definition_memory" {
  description = "Amount of memory to assign to a container. https://docs.aws.amazon.com/batch/latest/userguide/job_definition_parameters.html#ContainerProperties-resourceRequirements-Fargate-memory-vcpu"
  type        = number
  default     = 512
}

variable "job_definition_platform_version" {
  description = "Specify the Fargate platform version. Possible values for platformVersion are 1.3.0, 1.4.0, and LATEST."
  type        = string
  default     = "LATEST"
}

variable "job_definition_environment_variables" {
  description = "List of environemnt variables to be passed onto container."
  default     = null
}

variable "compute_resource_type" {
  description = "This must be either FARGATE or FARGATE_SPOT."
  type        = string
  default     = "FARGATE"
}

variable "compute_resource_max_vcpus" {
  description = "The maximum number of EC2 vCPUs that an environment can reach."
  type        = number
  default     = 16
}

variable "compute_resource_subnet_ids" {
  description = "List of subnet ids for aws batch compute environment."
  type        = list(string)
  default     = null
}

variable "compute_resource_security_groups" {
  description = "List of security groups for aws batch compute environment."
  type        = list(string)
  default     = null
}

variable "job_queue_state" {
  description = "The state of the job queue. Must be one of: ENABLED or DISABLED"
  type        = string
  default     = "ENABLED"
}

variable "job_queue_priority" {
  description = "The priority of the job queue"
  type        = number
  default     = 1
}

variable "job_queue_scheduling_policy_arn" {
  description = "The ARN of the fair share scheduling policy. If this parameter isn't specified, the job queue uses a first in, first out (FIFO) scheduling policy."
  type        = string
  default     = null
}

variable "event_rule_schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  default     = "cron(0 20 * * ? *)"
}

variable "event_rule_is_enabled" {
  description = "Whether the rule should be enabled"
  default     = true
}