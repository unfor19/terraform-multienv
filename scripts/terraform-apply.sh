#!/bin/bash
set -e
if [[ -z "$TF_VAR_app_name" ]]; then
    echo "[ERROR] Must set TF_VAR_app_name environment variable"
    exit
fi

if [[ -z "$TF_VAR_region" ]]; then
    echo "[ERROR] Must set TF_VAR_region environment variable"
    exit
fi

BRANCH_NAME=$(git branch --show-current)
BRANCH_NAME=${BRANCH_NAME//\//-}

cd "${BRANCH_NAME}"/ || exit
terraform init -input=false
terraform get
terraform validate
terraform plan -out=plan.tfout -var environment="${BRANCH_NAME}"
terraform apply -auto-approve plan.tfout 
