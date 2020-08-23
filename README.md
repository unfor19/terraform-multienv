# terraform-monorepo

A mono-repo template for maintaining cloud infrastructure with Terraform. All environments (development, staging and production) are maintained in the same repository.

## Assumptions

- \${app_name} = `tfmonorepo`
- \${environment} = `development` or `staging` or `production`
- \${ci-cd-tool} = `drone`
- `development` and `staging` are on the same AWS account
- `production` is on a different AWS account
- Branches names are aligned with environments names [`development`, `staging`, `production`]
- The CI/CD tool supports the variable `${BRANCH_NAME}`, for example `${DRONE_BRANCH}`
- We're going to create a VPC, Subnets and Routing Tables per environment (all free)

## Getting Started

- Terraform Backend - Create the following resources per environment (6 total)
  <br>(Optional) Deploy the backend CloudFormation template
  - S3 Bucket
    1.  Name: `${app_name}-state-${environment}`
    1.  Versioning: `Enabled`
    1.  Access: `Block All`
  - DynamoDB Table
    1.  Name: `${app_name}-state-lock-${environment}`
    1.  Primary Key (partition key): `LockID`
    1.  Billing Mode: `PROVISIONED`
    1.  Read/Write capacity: `1`
- (Optional) Deploying with your machine requires terraform v0.12.28
  <br>OS values: [`linux`, `darwin`, `windows`]
  <br>`curl -sL -O https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_${OS}_amd64.zip`

## Methodology

### Repository Structure

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

### Recommendations

- **Infrastructure repository** should **separated** from the **Application respository**
- **Modules** should be stored in a **different repository**
- **Feature branch** per environment **complicates** the whole process, though it is possible, it's not recommended
- **IAM Roles** for self-hosted CI/CD runners (nodes) are **preferred over AWS key/secret**
