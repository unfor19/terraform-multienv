#!/bin/bash
set -e
_LIVE_DIR=${LIVE_DIR:=live}
_BACKEND_TPL=${BACKEND_TPL:=backend.tf.tpl}

if [[ -n "$BRANCH_NAME" ]]; then
    _BRANCH_NAME=${BRANCH_NAME}
else
    _BRANCH_NAME=$(git branch --show-current)
fi

_BRANCH_NAME=${_BRANCH_NAME//\//-}

if [[ ! -d "$_BRANCH_NAME" ]]; then
    echo "[ERROR] Branch directory doesn't exist - '$_BRANCH_NAME'"
    exit 1
fi

if [[ -d "$_LIVE_DIR" ]]; then
    if [[ ! -f "${_LIVE_DIR}/${_BACKEND_TPL}" ]]; then
        echo "[ERROR] The file backend.tf.tpl doesn't exist - $_BACKEND_TPL"
        exit 1
    fi
else
    echo "[ERROR] The supplied live directory doesn't exist - $_LIVE_DIR"
    exit 1
fi

if [[ -z "$TF_VAR_app_name" ]]; then
    echo "[ERROR] Must set TF_VAR_app_name environment variable"
    exit 1
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
