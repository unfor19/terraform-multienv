# terraform-multienv

A template for maintaining a multiple environments infrastructure with [Terraform](https://www.terraform.io/). This template includes a CI/CD process, that applies the infrastructure in an AWS account.

<table>
   <tr>
      <td>environment</td>
      <td><a href="https://github.com/unfor19/terraform-multienv/blob/dev/.drone.yml">drone.io</a></td>
      <td><a href="https://github.com/unfor19/terraform-multienv/blob/dev/.github/workflows/pipeline.yml">GitHub Actions</a></td>
      <td><a href="https://github.com/unfor19/terraform-multienv/blob/dev/.circleci/config.yml">Circle Ci</a></td>
      <td><a href="https://github.com/unfor19/terraform-multienv/blob/dev/.travis.yml">Travis CI</a></td>
   </tr>
   <tr>
      <td>dev</td>
      <td><a href="https://cloud.drone.io/unfor19/terraform-multienv"><img src="https://cloud.drone.io/api/badges/unfor19/terraform-multienv/status.svg?ref=refs/heads/dev" /></a></td>
      <td><a href="https://github.com/unfor19/terraform-multienv/actions?query=workflow%3Apipeline"><img src="https://github.com/unfor19/terraform-multienv/workflows/pipeline/badge.svg?branch=dev" /></a></td>
      <td><a href="https://app.circleci.com/pipelines/github/unfor19/terraform-multienv?branch=dev"><img src="https://circleci.com/gh/unfor19/terraform-multienv/tree/dev.svg?style=svg" /></a></td>
      <td><a href="https://travis-ci.com/github/unfor19/terraform-multienv"><img src="https://travis-ci.com/unfor19/terraform-multienv.svg?branch=dev" /></a></td>    
   </tr>
   <tr>
      <td>stg</td>
      <td><a href="https://cloud.drone.io/unfor19/terraform-multienv"><img src="https://cloud.drone.io/api/badges/unfor19/terraform-multienv/status.svg?ref=refs/heads/stg" /></a></td>
      <td><a href="https://github.com/unfor19/terraform-multienv/actions?query=workflow%3Apipeline"><img src="https://github.com/unfor19/terraform-multienv/workflows/pipeline/badge.svg?branch=stg" /></a></td>    
      <td><a href="https://app.circleci.com/pipelines/github/unfor19/terraform-multienv?branch=stg"><img src="https://circleci.com/gh/unfor19/terraform-multienv/tree/stg.svg?style=svg" /></a></td>
      <td><a href="https://travis-ci.com/github/unfor19/terraform-multienv"><img src="https://travis-ci.com/unfor19/terraform-multienv.svg?branch=stg" /></a></td>        
   </tr>
   <tr>
      <td>prd</td>
      <td><a href="https://cloud.drone.io/unfor19/terraform-multienv"><img src="https://cloud.drone.io/api/badges/unfor19/terraform-multienv/status.svg?ref=refs/heads/prd" /></a></td>
      <td><a href="https://github.com/unfor19/terraform-multienv/actions?query=workflow%3Apipeline"><img src="https://github.com/unfor19/terraform-multienv/workflows/pipeline/badge.svg?branch=prd" /></a></td>
      <td><a href="https://app.circleci.com/pipelines/github/unfor19/terraform-multienv?branch=prd"><img src="https://circleci.com/gh/unfor19/terraform-multienv/tree/prd.svg?style=svg" /></a></td>
      <td><a href="https://travis-ci.com/github/unfor19/terraform-multienv"><img src="https://travis-ci.com/unfor19/terraform-multienv.svg?branch=prd" /></a></td>        
   </tr>
</table>

## Assumptions

- Branches names are aligned with environments names, for example `dev`, `stg` and `prd`
- The CI/CD tool supports the variable `${BRANCH_NAME}`, for example `${DRONE_BRANCH}`
- The directory `./live` contains infrastructure-as-code files - `*.tf`, `*.tpl`, `*.json`

- Multiple Environments

  - All environments are maintained in the same git repository
  - Hosting environments in different AWS account is supported (and recommended)

- Variables

  - \${app_name} = `tfmultienv`
  - \${environment} = `dev` or `stg` or `prd`

## Getting Started

1. We're going to create
   - AWS VPC, Subnets and Routing Tables per environment (all free)
   - [Terraform remote backend](https://www.terraform.io/docs/backends/types/s3.html) - S3 bucket and DynamoDB table
1. Create a new GitHub repository by clicking - [Use this template](https://github.com/unfor19/terraform-multienv/generate)
1. Edit `./.drone.yml` - Find and Replace `tfmultienv` and `eu-west-1`
1. CI/CD setup

   1. AWS Console > [Create an IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) for CI/CD per environment
      - Name: `cicd-${environment}`
      - Permissions: Allow `Programmatic Access` and attach the IAM policy `AdministratorAccess` (See [Recommendations](https://github.com/unfor19/terraform-multienv#security))
      - [Create AWS Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) and save them in a safe place, we'll use them in the next step
   1. drone.io > Create [repository secrets](https://docs.drone.io/secret/repository/) for AWS Access Keys per environment

      - Sign in with your GitHub account to [drone.io](https://cloud.drone.io/login) and activate your newly created git repository
      - Create secrets per environment for each AWS Access Keys pair, for example
        1. `aws_access_key_id_dev`
        1. `aws_secret_access_key_dev`
           ![drone-secrets-example](https://unfor19-tfmultienv.s3-eu-west-1.amazonaws.com/assets/drone-secrets-example.png)
           <br>**IMPORTANT**: The names of the secrets are not arbitrary, make sure you set them as shown in the example above

1. Deploy infrastructure - Commit and push the changes to your repository

   ```bash
   git checkout dev
   git add .
   git commit -m "deploy dev"
   git push -U origin dev
   ```

1. Check out your CI/CD logs in [Drone Cloud](https://cloud.drone.io) and the newly created resources in AWS Console > VPC.<br>To watch the CI/CD logs of this repository - [unfor19/terraform-multienv](https://cloud.drone.io/unfor19/terraform-multienv/9/1/2)

1. Promote `dev` environment to `stg`

   ```bash
   git checkout stg
   git merge dev
   git push
   ```

1. That's it, you've just deployed two identical environments, go ahead and do the same with `prd`

## Recommendations

### Generic

- **Naming Convention** should be consistent across your application and infrastructure. Avoid using `master` for `production`. A recommended set of names: `dev`, `tst` (qa), `stg` and `prd`. Using shorter names is preferred, since some AWS resources' names have a character limit
- **Resources Names** should **contain the environment name**, for example `tfmultienv-natgateway-prd`
- [Terraform remote backend](https://www.terraform.io/docs/backends/types/s3.html) costs are negligible (less than 1\$ per month)
- **Using Multiple AWS Accounts** for hosting different environments is recommended.<br>The way I implement it - `dev` and `stg` in the same account and `prd` in a different account

### Terraform

- **backend.tf.tpl** - Terraform Remote Backend settings per environment. The script [prepare-files-folders.sh](./scripts/prepare-files-folders.sh) replaces `APP_NAME` with `TF_VARS_app_name` and `ENVIRONMENT` with `BRANCH_NAME`
- **Remote Backend** is deployed with a CloudFormation template to avoid the chicken and the egg situation
- **Locked Terraform tfstate** occurs when a CI/CD process is running per environment. Stopping and restarting, or running multiple deployments to the same environment will result in an error. This is the expected behavior, we don't want multiple entities (CI/CD or Users) to deploy to the same environment at the same time
- **Unlock Terraform tfstate** by deleting the **md5 item** from the state's DynamoDB table, for example
  - Table Name: `${app_name}-state-lock-${environment}`
  - Item Name: `${app_name}-state-${environment}/terraform.tfstate-md5`

### Security

- **AdministratorAccess Permission for CI/CD** should be used only in early dev stages. After running a few successful deployments, make sure you **restrict the permissions** per environment and follow the [least-previleged best practice](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege). Use CloudTrail to figure out which IAM policies the CI/CD user needs, a great tool for that - [trailscraper](https://github.com/flosell/trailscraper)
- **IAM Roles** for self-hosted CI/CD runners (nodes) are **preferred over AWS key/secret**

### Git

- **Default Branch** is **dev** since this is the branch that is mostly used
- **Branches Names** per environment makes the whole CI/CD process **simpler**
- **Feature Branch** per environment **complicates** the whole process, since creating an environment per feature-branch means creating a Terraform Backend per feature-branch. Though it is possible, it's not recommended
- **Updating Environment Infrastructure** is done with **git push** and **git merge**, this way we can audit the changes

### Repository Structure

- **Modules** should be stored in a **different repository**
- **Infrastructure Repository** should **separated** from the **Frontend and Backend Respositories**

## References

- To get started with Terraform, watch this webinar - [Getting started with Terraform in AWS
  ](https://www.youtube.com/watch?v=cBDmoC7QonA)
- Terraform Best Practices - [ozbillwang/terraform-best-practices](https://github.com/ozbillwang/terraform-best-practices)

## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/terraform-multienv/blob/master/LICENSE) file for details
