#!/bin/bash
set -e
if [[ -z "$TF_VAR_app_name" ]]; then
    echo "[ERROR] Must set TF_VAR_app_name environment variable"
    exit
fi

if [[ -z "$AWS_REGION" ]]; then
    echo "[ERROR] Must set AWS_REGION environment variable"
    exit
fi

BRANCH_NAME=$(git branch --show-current)
_TEMPLATE_PATH="cloudformation/cfn-tfbackend.yml"
_STACK_NAME="${TF_VAR_app_name}-${BRANCH_NAME}"
_STACK_EXISTS=$(trap 'aws cloudformation describe-stacks --stack-name '"$_STACK_NAME"'' EXIT)
_STACK_EXISTS=$(echo "$_STACK_EXISTS" | grep "CreationTime")
if [[ -z "$_STACK_EXISTS" ]]; then
    echo "[LOG] Terraform backend CloudFormation doesn't exist, creating it ..."
    aws cloudformation deploy --stack-name "$_STACK_NAME" \
        --template-file "$_TEMPLATE_PATH" \
        --parameter-overrides AppName="$TF_VAR_app_name" Environment="$BRANCH_NAME"
else
    echo "[LOG] Terraform backend CloudFormation stack exists, do nothing"
fi
