data "aws_region" "current" {}

data "aws_caller_identity" "this" {}

data "aws_ecr_authorization_token" "token" {}

# VPC

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
    Name = "${var.environment}-vpc"
  }
}


# public subnets

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.environment}-Public Subnet ${count.index + 1}"
  }
}

# private subnets
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.environment}-Private Subnet ${count.index + 1}"
  }
}

# internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-internet-gateway"
  }
}


# public route table creation

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.environment}-public-route-table"
  }
}

# public subnet association
resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public-rt.id
}

# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {
  # vpc        = true
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "${var.environment}-nat-ip"
  }
}

# # NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = element(aws_subnet.public_subnets.*.id, 0)
  tags = {
    Name        = "${var.environment}-nat-gateway"
  }
}

# # private route table creation

resource "aws_route_table" "private-rt" {
 vpc_id = aws_vpc.main.id

 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_nat_gateway.nat.id
 }

 tags = {
   Name = "${var.environment}-private-route-table"
 }
}

# # private subnet association
resource "aws_route_table_association" "private_subnet_asso" {
 count = length(var.private_subnet_cidrs)
 subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
 route_table_id = aws_route_table.private-rt.id
}

resource "aws_s3_bucket" "source_bucket" {
  bucket = "regov-hari-devops-source"
  acl    = "private"
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket = "regov-hari-devops-destination"
  acl    = "private"
}


resource "aws_security_group" "batch_fargate_sg" {
  name        = "batch-fargate-security-group"
  description = "Security group for AWS Batch Fargate compute environment"

  vpc_id = aws_vpc.main.id  # Replace aws_vpc.example with your VPC ID

  // Inbound rule: Allow HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Outbound rule: Allow all traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


locals {
  account_id     = data.aws_caller_identity.this.account_id
  ecr_address    = format("%v.dkr.ecr.%v.amazonaws.com", local.account_id, data.aws_region.current.name)
  ecr_repo       = aws_ecr_repository.compute_image.id
  image_tag      = coalesce(var.image_tag, formatdate("YYYYMMDDhhmmss", timestamp()))
  ecr_image_name = format("%v/%v:%v", local.ecr_address, local.ecr_repo, local.image_tag)
}

provider "docker" {
  registry_auth {
    address  = local.ecr_address
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

# resource "docker_registry_image" "build_image" {
#   name = local.ecr_image_name

#   build {
#     context    = var.docker_source_path
#     dockerfile = var.docker_file_path
#     build_args = var.docker_build_args
#   }
# }

resource "aws_ecr_repository" "compute_image" {
  name                 = var.ecr_repository_name
  image_tag_mutability = var.ecr_image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.ecr_scan_on_push
  }
  encryption_configuration {
    encryption_type = var.ecr_encryption_type
  }
  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.compute_image.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Only keep ${var.ecr_lifecycle_image_days} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": ${var.ecr_lifecycle_image_days}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_cloudwatch_log_group" "batch_log_group" {
  name              = "/aws/batch/${var.app}/${var.component}/${var.environment}"
  retention_in_days = var.log_group_retention_in_days
  kms_key_id    = var.log_group_kms_key_arn
}

resource "aws_iam_role" "batch_service_role" {
  name = "batch-service-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"]
  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_instance_role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy","arn:aws:iam::aws:policy/AmazonS3FullAccess","arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly","arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess","arn:aws:iam::aws:policy/SecretsManagerReadWrite"]
}

resource "aws_batch_job_definition" "batch_job_definition" {
  name           = "${var.component}-${var.environment}-${var.app}"
  type           = "container"
  propagate_tags = var.job_definition_propagate_tags
  platform_capabilities = [
    "FARGATE",
  ]
  container_properties = jsonencode({
    command = var.job_definition_command
    image = "297867106429.dkr.ecr.ap-south-1.amazonaws.com/test-batch-job:latest"
    resourceRequirements = [
      {
        type = "VCPU"
        value = "${tostring(var.job_definition_vcpu)}"
      },
      {
        type = "MEMORY"
        value = "${tostring(var.job_definition_memory)}"
      }
    ]
    fargatePlatformConfiguration = {
      platformVersion = var.job_definition_platform_version
    }
    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group = aws_cloudwatch_log_group.batch_log_group.name
        awslogs-region = data.aws_region.current.name
      }
    }
    executionRoleArn = aws_iam_role.ecs_task_execution_role.arn
    environment = var.job_definition_environment_variables
  })
#   container_properties = <<CONTAINER_PROPERTIES
# {
#   "command": ${jsonencode(var.command)}, 
#   "image": "${local.ecr_image_name}",
#   "fargatePlatformConfiguration": {
#     "platformVersion": "${var.platform_version}"
#   },
#   "resourceRequirements": [
#     {"type": "VCPU", "value": "${var.vcpu}"},
#     {"type": "MEMORY", "value": "${var.mem}"}
#   ],
#   "logConfiguration":{
#     "logDriver": "awslogs",
#     "options": {
#       "awslogs-group": "${aws_cloudwatch_log_group.batch_log_group.name}",
#       "awslogs-region": "${data.aws_region.current.name}"
#     }
#   },
#   "environment": ${jsonencode(var.environment_variables)},
#   "executionRoleArn": "${aws_iam_role.ecs_task_execution_role.arn}"
# }
# CONTAINER_PROPERTIES 
  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

resource "aws_batch_compute_environment" "compute_environment" {
  compute_environment_name = "${var.component}-${var.environment}-${var.app}"
  type                     = "MANAGED"
  compute_resources {
    subnets            = aws_subnet.private_subnets.*.id
    security_group_ids = [aws_security_group.batch_fargate_sg.id]
    type               = var.compute_resource_type
    max_vcpus          = var.compute_resource_max_vcpus
  }
  service_role = aws_iam_role.batch_service_role.arn
  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
  depends_on = [aws_iam_role.batch_service_role]
}

resource "aws_batch_job_queue" "job_queue" {
  name                  = "${var.component}-${var.environment}-${var.app}"
  state                 = var.job_queue_state
  priority              = var.job_queue_priority
  scheduling_policy_arn = var.job_queue_scheduling_policy_arn
  compute_environments = [
    aws_batch_compute_environment.compute_environment.arn
  ]
  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

resource "aws_iam_role" "event_rule_batch_execution_role" {
  name = "event_rule_batch-execution-role-${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSBatchServiceEventTargetRole"]
  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name = "${var.component}-${var.environment}-${var.app}"
  description = "Event Rule to trigger batch job"
  schedule_expression = var.event_rule_schedule_expression
  role_arn = aws_iam_role.event_rule_batch_execution_role.arn
  is_enabled = var.event_rule_is_enabled
  tags = {
    app         = var.app
    component   = var.component
    environment = var.environment
  }
}

resource "aws_cloudwatch_event_target" "batch_event_target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "Batch"
  role_arn = aws_iam_role.event_rule_batch_execution_role.arn
  arn = aws_batch_job_queue.job_queue.arn
  batch_target {
    job_definition = aws_batch_job_definition.batch_job_definition.arn
    job_name = "${var.component}-${var.environment}-${var.app}"
  }
}

