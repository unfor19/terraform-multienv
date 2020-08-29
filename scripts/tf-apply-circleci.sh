#!/bin/bash
mkdir -p ${CIRCLE_BRANCH}/
cp live/*.${CIRCLE_BRANCH} ${CIRCLE_BRANCH}/
cp live/*.tf ${CIRCLE_BRANCH}/
cp live/*.tpl ${CIRCLE_BRANCH}/ 2>/dev/null || true
mv ${CIRCLE_BRANCH}/backend.tf.${CIRCLE_BRANCH} ${CIRCLE_BRANCH}/backend.tf

declare -n AWS_ACCESS_KEY_ID_SECRET_NAME=AWS_ACCESS_KEY_ID_${CIRCLE_BRANCH}
declare -n AWS_SECRET_ACCESS_KEY_SECRET_NAME=AWS_SECRET_ACCESS_KEY_${CIRCLE_BRANCH}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID_SECRET_NAME}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY_SECRET_NAME}
cd "${CIRCLE_BRANCH}"/ || exit
terraform version
rm -rf .terraform
terraform init -input=false
terraform get
terraform validate
terraform plan -out=plan.tfout -var environment=${CIRCLE_BRANCH}
terraform apply -auto-approve plan.tfout 
rm -rf .terraform
