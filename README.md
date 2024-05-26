
Hi Team,

I've developed the following resources using Terraform, based on the architecture outlined below:

In this solution, I've used a straightforward Python application for batch processing. The source code for this application is available in the `src` directory.

![image](https://github.com/hari36135/Regov-serverless-batch/assets/58912507/7af4b26a-da94-443d-a7a6-11ba543f2af1)


Architecture Overview:

The architecture consists of two primary components: Code Pipeline and Serverless Batch.

1. **Code Pipeline:** Upon a developer's code push to CodeCommit, the pipeline automatically initiates. It's responsible for building the Docker image and pushing it to the Elastic Container Registry (ECR).

2. **Serverless Batch:** To address our specific needs, I've defined the batch process using the Docker image mentioned earlier. Additionally, I've configured job queues and an EventBridge to trigger these jobs at defined intervals. Upon triggering, the batch job copies contents from the source bucket to the destination bucket.

This design encapsulates our solution, ensuring efficient batch processing as per our requirements. Let me know if you need further clarification or details!

### What can be improved in this solution:

1. **Streamline the IAM role to least privilege:**
   - Review the permissions granted to the IAM role and ensure that it follows the principle of least privilege. Remove any unnecessary permissions to minimize the risk of unauthorized access.

2. **Ensure Application uses IAM role (Current app is using hardcoded credentials):**
   - Update the application code to utilize IAM roles for accessing AWS services instead of hardcoded credentials. This enhances security and simplifies credential management by leveraging AWS Identity and Access Management (IAM) features.


## Directory Structure
```shell
Codepipeline-Fargate-batch
├── data.tf
├── execute
│   └── executables
│       ├── .terraform
│       │   ├── modules
│       │   │   └── modules.json
│       │   └── providers
│       │       └── registry.terraform.io
│       │           ├── hashicorp
│       │           │   └── aws
│       │           │       └── 5.51.1
│       │           │           └── windows_amd64
│       │           │               ├── LICENSE.txt
│       │           │               └── terraform-provider-aws_v5.51.1_x5.exe
│       ├── .terraform.lock.hcl
│       ├── data.tf
│       ├── locals.tf
│       ├── main.tf
│       ├── output.tf
│       ├── src
│       │   ├── buildspec_build.yml
│       │   ├── Dockerfile
│       │   ├── main.py
│       │   └── requirements.txt
│       ├── terraform.tfstate
│       ├── terraform.tfstate.backup
│       ├── terraform.tfvars
│       └── variables.tf
├── image.png
├── locals.tf
├── modules
│   ├── batch-fargate-docker
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── providers.tf
│   │   └── variable.tf
│   ├── codebuild
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── codecommit
│   │   ├── data.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── codepipeline
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── iam-role
│   │   ├── data.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   ├── kms
│   │   ├── data.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── README.md
│   │   └── variables.tf
│   └── s3
│       ├── main.tf
│       ├── outputs.tf
│       ├── provider.tf
│       ├── README.md
│       └── variables.tf
├── README.md
└── templates
    ├── buildspec_build.yml

```


## Installation

#### Step 1: Clone this repository.

```shell
git@github.com:aws-samples/aws-codepipeline-terraform-cicd-samples.git
```


#### Step 2: Update the variables in `execute/executables/terraform.tfvars` based on your requirement. Make sure you ae updating the variables project_name, environment, source_repo_name, source_repo_branch, create_new_repo, stage_input and build_projects.

- If you are planning to use an existing terraform CodeCommit repository, then update the variable create_new_repo as false and provide the name of your existing repo under the variable source_repo_name
- If you are planning to create new terraform CodeCommit repository, then update the variable create_new_repo as true and provide the name of your new repo under the variable source_repo_name


#### Step 3: Configure the AWS Command Line Interface (AWS CLI) where this IaC is being executed. For more information, see [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).

#### Step 4: Initialize the directory. Run terraform init and plan

#### Step 5: Start a Terraform run using the command terraform apply


**Note1**: The IAM Role used by the newly created pipeline is very restrictive and follows the Principle of least privilege. Please update the IAM Policy with the required permissions. 
Alternatively, use the _**create_new_role = false**_ option to use an existing IAM role and specify the role name using the variable _**codepipeline_iam_role_name**_

**Note2**: If the **create_new_repo** flag is set to **true**, a new blank repository will be created with the name assigned to the variable **_source_repo_name_**. Since this repository will not be containing the templates folder specified in Step 3 nor any code files, the initial run of the pipeline will be marked as failed in the _Download-Source_ stage itself.

**Note3**: If the **create_new_repo** flag is set to **false** to use an existing repository, ensure the pre-requisite steps specified in step 3 have been done on the target repository.





