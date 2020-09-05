#!/bin/bash
set -e
_BRANCH_NAME=$(git branch --show-current)
_BRANCH_NAME=${_BRANCH_NAME//\//-}

if [[ ! -d "$_BRANCH_NAME" ]]; then
    echo "[ERROR] Branch directory doesn't exist - '$_BRANCH_NAME'"
fi

if [[ -z "$TF_VAR_app_name" ]]; then
    echo "[ERROR] Must set TF_VAR_app_name environment variable"
    exit
fi

if [[ -z "$TF_VAR_region" ]]; then
    echo "[ERROR] Must set TF_VAR_region environment variable"
    exit
fi

cd "${_BRANCH_NAME}"/ || exit
terraform init -input=false
terraform get
terraform validate
terraform plan -out=plan.tfout -var environment="${_BRANCH_NAME}"
terraform apply -auto-approve plan.tfout 
