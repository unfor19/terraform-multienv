# terraform-multienv

A template for maintaining a multiple environments infrastructure with [Terraform](https://www.terraform.io/). This template includes a CI/CD process, that applies the infrastructure in an AWS account.

<table>
   <tr>
      <td>development</td><td><a href="https://cloud.drone.io/unfor19/terraform-multienv"><img src="https://cloud.drone.io/api/badges/unfor19/terraform-multienv/status.svg?ref=refs/heads/development" /></a></td>
   </tr>
   <tr>
      <td>staging</td><td><a href="https://cloud.drone.io/unfor19/terraform-multienv"><img src="https://cloud.drone.io/api/badges/unfor19/terraform-multienv/status.svg?ref=refs/heads/staging" /></a></td>
   </tr>
   <tr>
      <td>production</td><td><a href="https://cloud.drone.io/unfor19/terraform-multienv"><img src="https://cloud.drone.io/api/badges/unfor19/terraform-multienv/status.svg?ref=refs/heads/production" /></a></td>
   </tr>
</table>

<table>
   <tr>
      <td align="center">drone.io<br><br>
         <a href="https://cloud.drone.io/unfor19/terraform-multienv"><img width="100px" height="100px" src="https://bargs.link/assets/droneio-logo.png" alt="drone.io" /></a>
      </td>
      <td align="center">GitHub Actions<br><br>
         <a href="https://github.com/unfor19/terraform-multienv/actions"><img width="100px" height="100px" src="https://bargs.link/assets/githubactions-logo.png" alt="drone.io" /></a>
      </td>
      <td align="center">CircleCI<br><br>
         <a href="https://app.circleci.com/pipelines/github/unfor19/terraform-multienv"><img width="100px" height="100px" src="https://bargs.link/assets/circleci-logo.png" alt="drone.io" /></a>
      </td>
   </tr>
</table>

## Assumptions

- Branches names are aligned with environments names, for example `development`, `staging` and `production`
- The CI/CD tool supports the variable `${BRANCH_NAME}`, for example `${DRONE_BRANCH}`

- Multiple Environments

  - You have multiple environments, for example `development`, `staging` and `production`
  - All environments are maintained in the same git repository
  - Hosting environments in different AWS account is supported (and recommended)

- Variables

  - \${app_name} = `tfmultienv`
  - \${environment} = `development` or `staging` or `production`
  - \${ci-cd-tool} = `drone`

## Getting Started

1. We're going to create a VPC, Subnets and Routing Tables per environment (all free)
1. Clone this repository or [Use as a template](https://github.com/unfor19/terraform-multienv/generate)
1. Deploy Terraform Remote Backend - Create an S3 bucket to store `tfstate` and a DynamoDB Table for [state locking](https://www.terraform.io/docs/state/locking.html), per environment

   [![Launch in Ireland](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png) Ireland (eu-west-1)](https://eu-west-1.console.aws.amazon.com/cloudformation/home?region=eu-west-1#/stacks/quickcreate?templateURL=https://unfor19-tfmultienv.s3-eu-west-1.amazonaws.com/cloudformation/cfn-tfbackend.yml)

   [![Launch in Virginia](https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png) Virginia (us-east-1)](https://us-east-1.console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/quickcreate?templateURL=https://unfor19-tfmultienv.s3-eu-west-1.amazonaws.com/cloudformation/cfn-tfbackend.yml)

   <details><summary>
   Other regions
   </summary>

   To deploy in other regions, replace AWS_REGION with the region's code.

   `https://AWS_REGION.console.aws.amazon.com/cloudformation/home?region=AWS_REGION#/stacks/quickcreate?templateURL=https://unfor19-tfmultienv.s3-eu-west-1.amazonaws.com/cloudformation/cfn-tfbackend.yml`

   </details>

   <details><summary>
   Deployed resources
   </summary>

   1. S3 Bucket
      - Name: `${app_name}-state-${environment}`
      - Versioning: `Enabled`
      - Access: `Block All`
   1. DynamoDB Table
      - Name: `${app_name}-state-lock-${environment}`
      - Primary Key (partition key): `LockID`
      - Billing Mode: `PROVISIONED`
      - Read/Write capacity: `1`

   </details>

1. Find and Replace `tfmultienv` and `eu-west-1`
   1. `./live/backend.tf.${environment}`
   1. `./live/variables.tf`
   1. `./.${ci-cd-tool}.yml`
1. CI/CD setup

   1. Sign in with your GitHub account to [drone.io](https://cloud.drone.io/login) and activate your newly created git repository
   1. AWS Console > Create an IAM User for CI/CD, per environment

      - Name: `cicd-${environment}`
      - Permissions: `AdministratorAccess` (See [Recommendations](https://github.com/unfor19/terraform-multienv#security))

   1. drone.io > Create [repository secrets](https://docs.drone.io/secret/repository/) for AWS credentials per environment, for example

      - aws_access_key_id\_**development**
      - aws_secret_access_key\_**development**

       <details><summary>
       Drone Secrets Example - Expand/Collapse
       </summary>

      ![drone-secrets-example](https://unfor19-terraform-multienv.s3-eu-west-1.amazonaws.com/assets/drone-secrets-example.png)

         </details>

      <br>**IMPORTANT**: The names of the secrets are not arbitrary, make sure you set them as shown in the example above

1. Commit and push the changes to your repository

   ```bash
   $ git checkout development
   $ git add .
   $ git commit -m "deploy development"
   $ git push -U origin development
   ```

1. Check out your CI/CD logs in [Drone Cloud](https://cloud.drone.io) and the newly created resources in AWS Console > VPC.<br>To watch the CI/CD logs of this repository - [unfor19/terraform-multienv](https://cloud.drone.io/unfor19/terraform-multienv/9/1/2)

1. Promote `development` environment to `staging`

   ```bash
   $ git checkout staging
   $ git merge development
   $ git push
   ```

1. That's it, you've just deployed two identical environments, go ahead and do the same with `production`

## Repository Structure

- `./`
  - Contains `README.md`, `.gitignore`, `LICENSE` and `.${ci-cd-tool}.yml`
  - `.${ci-cd-tool}.yml` - In this repository we're using [drone.io](https://drone.io)
- `./live/`
  - Contains `*.tf`, `*.tpl` and `backend.tf.${environment}`
  - `*.tf` - The infrastructure, **don't** put `modules` in this folder
  - `*.tpl` - In case you're using [templates files](https://www.terraform.io/docs/configuration/functions/templatefile.html)
  - `*.backend.tf.${environment}` - Hardcoded values of the terraform backend per environment
- `./cloudformation/`
  - Contains CloudFormation templates (`*.yml`), for example [cfn-tfbackend.yml](https://github.com/unfor19/terraform-multienv/blob/development/cloudformation/cfn-tfbackend.yml)
- `./scripts/`
  - Contains scripts which eases the development process (`*.sh`)

## Recommendations

### Generic

- **Naming Convention** should be consistent across your application and infrastructure. Avoid using `master` for `production`. A recommended set of names: `dev`, `tst` (qa), `stg` and `prd`. Using shorter names is preferred, since some AWS resources' names have a character limit. I'll probably change this repository's branches soon
- **Resources Names** should **contain the environment name**, for example `production`
- [Terraform remote backend](https://www.terraform.io/docs/backends/types/s3.html) costs are negligible (less than 1\$ per month)
- **Using Multiple AWS Accounts** for hosting different environments is recommended.<br>The way I implement it - development and `staging` in the same account and `production` in a different account

### Terraform

- **Remote Backend** is deployed with a CloudFormation template to avoid the chicken and the egg situation
- **Locked Terraform tfstate** occurs when a CI/CD process is running per environment. Stopping and restarting, or running multiple deployments to the same environment will result in an error. This is the expected behavior, we don't want multiple entities (CI/CD or Users) to deploy to the same environment at the same time
- **Unlock Terraform tfstate** by deleting the **md5 item** from the state's DynamoDB table, for example
  - Table Name: `${app_name}-state-lock-${environment}`
  - Item Name: `${app_name}-state-${environment}/terraform.tfstate-md5`

### Security

- **AdministratorAccess Permission for CI/CD** should be used only in early development stages. After running a few successful deployments, make sure you **restrict the permissions** per environment and follow the [least-previleged best practice](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege). Use CloudTrail to figure out which IAM policies the CI/CD user needs, a great tool for that - [trailscraper](https://github.com/flosell/trailscraper)
- **IAM Roles** for self-hosted CI/CD runners (nodes) are **preferred over AWS key/secret**

### Git

- **Default Branch** is **development** since this is the branch that is mostly used
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
