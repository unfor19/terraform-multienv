#!/bin/bash
_LIVE_DIR=${LIVE_DIR:=live}
_BACKEND_TPL=${BACKEND_TPL:=backend.tf.tpl}

if [[ -z "$BRANCH_NAME" ]]; then
    _BRANCH_NAME=$(git branch --show-current)
else
    _BRANCH_NAME=${BRANCH_NAME}
fi

_BRANCH_NAME=${_BRANCH_NAME//\//-}
_TEMPLATE_PATH=${TEMPLATE_PATH:="cloudformation/cfn-tfbackend.yml"}

if [[ -d "${_LIVE_DIR}" ]]; then
    if [[ ! -f "${_LIVE_DIR}/${_BACKEND_TPL}" ]]; then
        echo "[ERROR] The file backend.tf.tpl doesn't exist - $_BACKEND_TPL"
        exit 1
    fi
else
    echo "[ERROR] The supplied live directory doesn't exist - $_LIVE_DIR"
    exit 1
fi

if [[ ! -d "$_BRANCH_NAME" ]]; then
    echo "[ERROR] Branch directory doesn't exist - '$_BRANCH_NAME'"
    exit 1
fi

if [[ -z "$TF_VAR_app_name" ]]; then
    echo "[ERROR] Must set TF_VAR_app_name environment variable"
    exit 1
fi

if [[ -z "$AWS_REGION" || -z "$AWS_DEFAULT_REGION" ]]; then
    echo "[ERROR] Must set AWS_REGION and AWS_DEFAULT_REGION environment variables"
    exit 1
fi

_STACK_NAME="${TF_VAR_app_name}-${_BRANCH_NAME}"
_STACK_EXISTS=$(trap 'aws cloudformation describe-stacks --stack-name '"$_STACK_NAME"'' EXIT)
_STACK_EXISTS=$(echo "$_STACK_EXISTS" | grep "CreationTime")
if [[ -z "$_STACK_EXISTS" ]]; then
    echo "[LOG] Terraform backend CloudFormation doesn't exist, creating it ..."
    aws cloudformation deploy \
        --stack-name "$_STACK_NAME" \
        --template-file "$_TEMPLATE_PATH" \
        --parameter-overrides AppName="$TF_VAR_app_name" Environment="$_BRANCH_NAME"
else
    echo "[LOG] Terraform backend CloudFormation stack exists, do nothing"
fi
