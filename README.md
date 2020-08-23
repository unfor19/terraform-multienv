# terraform-monorepo

A [mono-repo](https://en.wikipedia.org/wiki/Monorepo) template for maintaining cloud infrastructure with [Terraform](https://www.terraform.io/). This template includes a CI/CD process, that applies the infrastructure in AWS account, by using [drone](https://drone.io)

## Assumptions

- All environments (development, staging and production) are maintained in the same repository.
- \${app_name} = `tfmonorepo`
- \${environment} = `development` or `staging` or `production`
- \${ci-cd-tool} = `drone`
- `development` and `staging` are in the same AWS account
- `production` is in a different AWS account
- Branches names are aligned with environments names [`development`, `staging`, `production`]
- The CI/CD tool supports the variable `${BRANCH_NAME}`, for example `${DRONE_BRANCH}`
- We're going to create a VPC, Subnets and Routing Tables per environment (all free)

## Getting Started

1. Clone this repository or [Use as a template](https://github.com/unfor19/terraform-monorepo/generate)
1. Terraform Backend - Create the following resources per environment
   <br>Four (4) in development&staging account and two (2) in production account (6 total)
   <br>
   <br>(Optional) Deploy with `./cloudformation/cfn-backend.yml` CloudFormation template
   <br>
   1. S3 Bucket
      - Name: `${app_name}-state-${environment}`
      - Versioning: `Enabled`
      - Access: `Block All`
   1. DynamoDB Table
      - Name: `${app_name}-state-lock-${environment}`
      - Primary Key (partition key): `LockID`
      - Billing Mode: `PROVISIONED`
      - Read/Write capacity: `1`
1. Find and Replace `tfmonorepo` and `eu-west-1` (if necessary)
   1. `./live/backend.tf.${environment}`
   1. `./live/variables.tf`
1. CI/CD setup

   1. Create an IAM User for CI/CD in both development&staging account and production account

      - Name: `cicd`
      - Permissions: `AdministratorAccess` (See Recommendations)

   1. Create secrets for AWS credentials per environment, example for `development`

      - aws_access_key_id\_**development**
      - aws_secret_access_key\_**development**
        <br>**IMPORTANT**: The names of the secrets are not arbitrary, make sure you set them properly

   1. Find and Replace application name `tfmonorepo` in `./.drone.yml`

1. Commit and push your changes to your repository
1. Check out the logs in [Drone Cloud](https://cloud.drone.io) and new resources in AWS Console

1. (Optional) [terraform v0.12.28](https://releases.hashicorp.com/terraform/0.12.28/) - for local development

## Repository Structure

- `./`
  - Contains `README.md`, `.gitignore`, `LICENSE` and `.${cd-cd-tool}.yml`
  - `.${cd-cd-tool}.yml` - In this repository we're using [drone.io](https://drone.io)
- `./live/`
  - Contains `*.tf`, `*.tpl` and `backend.tf.${environment}`
  - `*.tf` - The infrastructure, **don't** put `modules` in this folder
  - `*.tpl` - In case you're using [templates files](https://www.terraform.io/docs/configuration/functions/templatefile.html)
  - `*.backend.tf.${environment}` - Hardcoded values of the terraform backend per environment
- `./cloudformation/`
  - Contains CloudFormation templates (`*.yml`), for example `cfn-backend.yml`
- `./scripts/`
  - Contains scripts which improve the development process (`*.sh`)

## Recommendations

### Generic

- **Naming Convention** should be consistent across your application and infrastructure. Avoid using short names like `dev`, `develop`, `prod` or using `master` for `production`. Using full names is more explicit and clearer
- **Resources Names** should **contain the environment name**, for example `production`

### Security

- **AdministratorAccess Permission for CI/CD** should be used only in early development stages. After running a few successful deployments, make sure you **restrict the permissions** per environment and follow the [least-previleged best practice](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- **IAM Roles** for self-hosted CI/CD runners (nodes) are **preferred over AWS key/secret**

### Git

- **Default Branch** is **development** to avoid confusion
- **Branches Names** per environment makes the whole CI/CD process simpler
- **Feature Branch** per environment **complicates** the whole process, though it is possible, it's not recommended
- **Updating Environment Infrastructure** is possible with **git merge**

### Repository Structure

- **Modules** should be stored in a **different repository**
- **Infrastructure Repository** should **separated** from the **Frontend and Backend Respositories**
