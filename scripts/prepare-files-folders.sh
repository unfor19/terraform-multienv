#!/bin/bash
if [[ -z "$TF_VAR_app_name" ]]; then
    echo "[ERROR] Must set TF_VAR_app_name environment variable"
    exit
fi

if [[ -z "$AWS_REGION" ]]; then
    echo "[ERROR] Must set AWS_REGION environment variable"
    exit
fi

BRANCH_NAME=$(git branch --show-current)
BRANCH_NAME=${BRANCH_NAME//\//-}
[[ -d "$BRANCH_NAME" ]] && rm -r "$BRANCH_NAME"
mkdir -p "${BRANCH_NAME}"/
cp live/* "${BRANCH_NAME}"/
sed -i.bak 's~AWS_REGION~'"$AWS_REGION"'~' "${BRANCH_NAME}"/backend.tf.tpl
sed -i.bak 's~APP_NAME~'"$TF_VAR_app_name"'~' "${BRANCH_NAME}"/backend.tf.tpl
sed -i.bak 's~ENVIRONMENT~'"$BRANCH_NAME"'~' "${BRANCH_NAME}"/backend.tf.tpl
mv "${BRANCH_NAME}"/backend.tf.tpl "${BRANCH_NAME}"/backend.tf
echo "[LOG] Prepared files and folders for the environment - $BRANCH_NAME"
ls -lah "$BRANCH_NAME"
