#!/bin/bash
set -e
set -o pipefail
_LIVE_DIR=${LIVE_DIR:="live"}
_BACKEND_TPL=${BACKEND_TPL:="backend.tf.tpl"}
_TERRAFORM_APPLY=${TERRAFORM_APPLY:="false"}

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
terraform plan -out=plan.tfout -no-color -var environment="${_BRANCH_NAME}" 2>&1 | tee plan.md
no_changes=$(awk '/^No changes/' plan.md)
if [[ -z "$no_changes" ]]; then
    delimiter=$(awk '/^-----*$/{ print NR; exit }' plan.md)
    sed -i.bak -n ''$((delimiter+1))',$ p' plan.md
    delimiter=$(awk '/^-----*$/{ print NR; exit }' plan.md)
    sed -i.bak '1,'$((delimiter-1))'!d' plan.md
    sed -i.bak 's~^  ~~g' plan.md
    my_plan=$(awk '/^Plan:.*$/' plan.md)
fi

if [[ -n $my_plan && -z $no_changes ]]; then
    sed -i.bak "1s/^/### $my_plan/" plan.md
    sed -i.bak $'2s/^/\\`\\`\\`diff\\\n/' plan.md
    echo "\`\`\`" >> plan.md    
else
    echo "### No changes to be made" > plan.md
fi

if [[ "$_TERRAFORM_APPLY" = "true" && -n $my_plan && -z $no_changes ]]; then
    terraform apply -auto-approve plan.tfout 
fi
