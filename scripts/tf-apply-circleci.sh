#!/bin/bash
mkdir -p ${CIRCLE_BRANCH}/
cp live/*.${CIRCLE_BRANCH} ${CIRCLE_BRANCH}/
cp live/*.tf ${CIRCLE_BRANCH}/
cp live/*.tpl ${CIRCLE_BRANCH}/ 2>/dev/null || true
mv ${CIRCLE_BRANCH}/backend.tf.${CIRCLE_BRANCH} ${CIRCLE_BRANCH}/backend.tf

cd "${CIRCLE_BRANCH}"/ || exit
terraform version
rm -rf .terraform
terraform init -input=false
terraform get
terraform validate
terraform plan -out=plan.tfout -var environment=${CIRCLE_BRANCH}
terraform apply -auto-approve plan.tfout 
rm -rf .terraform
