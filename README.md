# terraform-multienv

A template for maintaining a multiple environments infrastructure with [Terraform](https://www.terraform.io/). This template includes a CI/CD process, that applies the infrastructure in an AWS account.

<table>
   <tr>
      <td>environment</td>
      <td><a href="https://github.com/unfor19/terraform-multienv/blob/dev/.github/workflows/pipeline.yml">GitHub Actions</a></td>
   </tr>
   <tr>
      <td>dev</td>
      <td><a href="https://github.com/unfor19/terraform-multienv/actions?query=workflow%3Apipeline"><img src="https://github.com/unfor19/terraform-multienv/workflows/pipeline/badge.svg?branch=dev" /></a></td>
   </tr>
   <tr>
      <td>stg</td>
      <td><a href="https://github.com/unfor19/terraform-multienv/actions?query=workflow%3Apipeline"><img src="https://github.com/unfor19/terraform-multienv/workflows/pipeline/badge.svg?branch=stg" /></a></td>    
   </tr>
   <tr>
      <td>prd</td>
      <td><a href="https://github.com/unfor19/terraform-multienv/actions?query=workflow%3Apipeline"><img src="https://github.com/unfor19/terraform-multienv/workflows/pipeline/badge.svg?branch=prd" /></a></td>
   </tr>
</table>

## Assumptions

- Branches names are aligned with environments names, for example `dev`, `stg` and `prd`
- The directory `./live` contains infrastructure-as-code files - `*.tf`, `*.tpl`, `*.json`

- Multiple Environments

  - All environments are maintained in the same git repository
  - Hosting environments in different AWS account is supported (and recommended)

- Variables

  - \${app_name} = `tfmultienv-example`
  - \${environment} = `dev` or `stg` or `prd`

## Getting Started

1. We're going to create the following resources per environment
   - AWS VPC, Subnets, Routes and Routing Tables, Internet Gateway
   - S3 bucket (website) and an S3 object (index.html)
   - [Terraform remote backend](https://www.terraform.io/docs/backends/types/s3.html) - S3 bucket and DynamoDB table
1. Create a new GitHub repository by clicking - [Use this template](https://github.com/unfor19/terraform-multienv/generate) and **don't tick** _Include all branches_
1. AWS Console > [Create IAM Users](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) for the CI/CD service per environment
   - Name: `${app_name}-${environment}-cicd`
   - Permissions: Allow `Programmatic Access` and attach the IAM policy `AdministratorAccess` (See [Recommendations](https://github.com/unfor19/terraform-multienv#security))
   - [Create AWS Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) and save them in a safe place, we'll use them in the next step
2. GitHub > Create the following [repository secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets#creating-encrypted-secrets-for-a-repository) for authenticating with AWS, according to the access keys that were created in previous steps

   - `GH_TOKEN_DOWNLOAD_ARTIFACT` - Create a [GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with `repo` access
   - `AWS_ACCESS_KEY_ID_DEV`
   - `AWS_SECRET_ACCESS_KEY_DEV`
   - `AWS_ACCESS_KEY_ID_STG`
   - `AWS_SECRET_ACCESS_KEY_STG`
   - `AWS_ACCESS_KEY_ID_PRD`
   - `AWS_SECRET_ACCESS_KEY_PRD`
     <br>**IMPORTANT**: Secrets **names** are maintained in [configmap.json](./configmap.json)
     ![github-secrets-example](https://unfor19-tfmultienv.s3-eu-west-1.amazonaws.com/assets/github-secrets-example.png)

3. Deploying the infrastructure - Commit and push changes to your repository

   ```
   git checkout dev
   git add .
   git commit -m "deploy dev"
   git push --set-upstream origin dev
   ```

4. Results

   - Newly created resources in AWS Console - VPC, S3 and DynamoDB Table
   - CI/CD logs in the Actions tab ([this repo's logs](https://github.com/unfor19/terraform-multienv/actions))
   - The URL of the deployed static S3 website is available in the `terraform-apply` logs, for example:
     1. `s3_bucket_url = terraform-20200912173059419600000001.s3-website-eu-west-1.amazonaws.com`

5. Create `stg` branch

   ```
   git checkout dev
   git checkout -b stg
   git push --set-upstream origin stg
   ```

6. GitHub > Promote `dev` environment to `stg`

   - Create a PR from `dev` to `stg`
   - The plan to `stg` is added as a comment by the [terraform-plan](https://github.com/unfor19/terraform-multienv/blob/dev/.github/workflows/terraform-plan.yml) pipeline
   - Merge the changes to `stg`, and check the [terraform-apply](https://github.com/unfor19/terraform-multienv/blob/dev/.github/workflows/terraform-apply.yml) pipeline in the Actions tab

7. That's it, you've just deployed two identical environments! Go ahead and do the same with `prd`

8. How to proceed from here
   1. Plan on `dev` - commit and push to non-live branch
   2. Promote feature branches to `dev` - create a PR to plan and merge to apply
   3. Promote `dev` to `stg` - create a PR to plan and merge to apply
   4. Promote `stg` to `prd` - create a PR to plan and merge to apply
   5. Revert changes in a non-live branch - [reverting a commit](https://git-scm.com/docs/git-revert.html)
   6. Revert changes in a live branch  (`dev`, `stg` and `prd`) - [reverting a PR](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/reverting-a-pull-request#reverting-a-pull-request)

## Recommendations

### Generic

- **Naming Convention** should be consistent across your application and infrastructure. Avoid using `master` for `production`. A recommended set of names: `dev`, `tst` (qa), `stg` and `prd`. Using shorter names is preferred, since some AWS resources' names have a character limit
- **Resources Names** should **contain the environment name**, for example `tfmultienv-natgateway-prd`
- [Terraform remote backend](https://www.terraform.io/docs/backends/types/s3.html) costs are negligible (less than 5\$ per month)
- **Using Multiple AWS Accounts** for hosting different environments is recommended.<br>The way I implement it - `dev` and `stg` in the same account and `prd` in a different account
- **Create a test environment** to test new resources or breaking changes, such as migrating from MySQL to Postgres. The main goal is to avoid breaking the `dev` environment, which means blocking the development team.

### Terraform

- **backend.tf.tpl** - Terraform Remote Backend settings per environment. The script [prepare-files-folders.sh](./scripts/prepare-files-folders.sh) replaces `APP_NAME` with `TF_VARS_app_name` and `ENVIRONMENT` with `BRANCH_NAME`
- **Remote Backend** is deployed with a CloudFormation template to avoid the chicken and the egg situation
- **Locked Terraform tfstate** occurs when a CI/CD process is running per environment. Stopping and restarting, or running multiple deployments to the same environment will result in an error. This is the expected behavior, we don't want multiple entities (CI/CD or Users) to deploy to the same environment at the same time
- **Unlock Terraform tfstate** by deleting the items from the state-lock DynamoDB table, for example
  - Table Name: `${app_name}-state-lock-${environment}`
  - Item Name: `${app_name}-state-${environment}/terraform.tfstate*`

### Security

- **AdministratorAccess Permission for CI/CD** should be used only in early dev stages. After running a few successful deployments, make sure you **restrict the permissions** per environment and follow the [least-previleged best practice](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege). Use CloudTrail to figure out which IAM policies the CI/CD user needs, a great tool for that - [trailscraper](https://github.com/flosell/trailscraper)
- **IAM Roles** for self-hosted CI/CD runners (nodes) are **preferred over AWS key/secret**

### Git

- **Default Branch** is **dev** since this is the branch that is mostly used
- **Branches Names** per environment makes the whole CI/CD process **simpler**

### Repository Structure

- **Modules** should be stored in a **different repository**
- **Infrastructure Repository** should be **separated** from the **Frontend and Backend Respositories**. There's no need to re-deploy the infrastructure each time the application changes (loosely coupled)

## References

- To get started with Terraform, watch this webinar - [Getting started with Terraform in AWS
  ](https://www.youtube.com/watch?v=cBDmoC7QonA)
- [Terraform Dynamic Subnets](https://dev.to/prodopsio/terraform-aws-dynamic-subnets-2cgo)
- Terraform Best Practices - [ozbillwang/terraform-best-practices](https://github.com/ozbillwang/terraform-best-practices)

## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/terraform-multienv/blob/master/LICENSE) file for details
