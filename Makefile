#!make
.ONESHELL:
.EXPORT_ALL_VARIABLES:

UNAME:=$(shell uname)

# Windows Git Bash
ifneq (,$(findstring NT, $(UNAME)))
_OS=windows
BASH_PATH=/usr/bin/bash
endif

# macOS
ifneq (,$(findstring Darwin, $(UNAME)))
_OS=macos
BASH_PATH=/bin/bash
endif

# Docker
ifneq ("$(wildcard /.dockerenv)","")
BASH_PATH=/bin/bash
endif


# Load dotenv per environment - only if CI != true
ifneq (${CI},true)
# Local

# Global dotent .env
ifneq ("$(wildcard .env)","")
include .env
endif

# Stage/Environment dotenv .env
ifneq ("$(wildcard .env.${STAGE})","")
include .env.${STAGE}
endif

else # (${CI},true)
# CI=true
BASH_PATH=/usr/bin/bash
endif # (${CI},true)

SHELL=${BASH_PATH}


# Generic Variables
TIMESTAMP:=$(shell date +%s)
DATE_TIMESTAMP:=$(shell date '+%Y-%m-%d')
ROOT_DIR:=${PWD}

# Terraform
TF_VAR_env:=${STAGE}
TF_VAR_environment:=${STAGE}

ifneq (${CI},true)
# Local - Requirement - Copy the "terraform" binary to "/usr/bin/local/terraform1.2.3"
# Enables support for running multiple Terraform versions on the same machine
TERRAFORM_BINARY=terraform${TERRAFORM_VERSION}
else
# CI=true
# In CI, there's only one Terraform version
TERRAFORM_BINARY=terraform
endif


# Variables that depend on git
ifndef GIT_BRANCH
GIT_BRANCH=$(shell git branch --show-current)
endif

GIT_BRANCH_SLUG=$(subst /,-,$(GIT_BRANCH))

ifndef GIT_BUILD_NUMBER
GIT_BUILD_NUMBER=99999
endif

ifndef GIT_COMMIT
GIT_COMMIT=$(shell git rev-parse HEAD)
endif
GIT_SHORT_COMMIT=$(shell ${GIT_COMMIT:0:8})

ifeq (${AWS_PROFILE},)
unexport AWS_PROFILE
endif

ifeq (${AWS_ACCESS_KEY_ID},)
unexport AWS_ACCESS_KEY_ID
endif

ifeq (${AWS_SECRET_ACCESS_KEY},)
unexport AWS_SECRET_ACCESS_KEY
endif

# Avoid opening aws-cli responses in default editor
export AWS_PAGER=


# Terraform
TF_VAR_app_name:=${APP_NAME}
TF_VAR_region:=${AWS_REGION}
TF_VAR_env:=${STAGE}
TF_VAR_environment:=${STAGE}
TERRAFORM_LIVE_DIR:=${ROOT_DIR}/live
TERRAFORM_PLAN_PATH:=${TERRAFORM_LIVE_DIR}/.${APP_NAME}-${STAGE}-plan
TERRAFORM_PLAN_LOG_PATH:=${TERRAFORM_LIVE_DIR}/.${APP_NAME}-${STAGE}-plan.log
TERRAFORM_APPLY_LOG_PATH:=${TERRAFORM_LIVE_DIR}/.${APP_NAME}-${STAGE}-apply.log
TERRAFORM_BACKENDTPL_PATH:=${TERRAFORM_LIVE_DIR}/backend.${STAGE}.tpl
TERRAFORM_BACKEND_CFN_PATH:=${ROOT_DIR}/cloudformation/cfn-tfbackend.yml
TERRAFORM_BACKEND_STACK_NAME=${APP_NAME}-terraform-backend-${STAGE}
TERRAFORM_BACKEND_STACK_LOG_PATH=${TERRAFORM_LIVE_DIR}/.${APP_NAME}-${STAGE}-backend.log

# To validate env vars, add "validate-MY_ENV_VAR" 
# as a prerequisite to the relevant target/step
validate-%:
	@if [ -z '${${*}}' ]; then echo 'Environment variable $* not set' && exit 1; fi


##-- GENERIC --

# Removes blank rows - fgrep -v fgrep
# Replace ":" with "" (nothing)
# Print a beautiful table with column
help: ## Available make commands
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:.* #~~' | column -t -s'#'
	@echo


usage: help


print-path:
	@env | grep ^PATH=


check-requirements-infra:
	@echo Checking requiments ...
	@aws --version | grep 'aws-cli/2\.[4-9].*'
	@${TERRAFORM_BINARY} version | grep '${TERRAFORM_VERSION}'


validate: validate-APP_NAME validate-STAGE validate-AWS_REGION

##.
##-- INFRA --
infra-prepare-backend: validate # Create Terraform backend S3Bucket and DynamoDB Table with CloudFormation
	@echo ${TIMESTAMP} > ${TERRAFORM_BACKEND_STACK_LOG_PATH}
	@aws cloudformation describe-stacks --region ${AWS_REGION} --stack-name ${TERRAFORM_BACKEND_STACK_NAME} 1>>${TERRAFORM_BACKEND_STACK_LOG_PATH} 2>>${TERRAFORM_BACKEND_STACK_LOG_PATH} || true
	@if grep 'does not exist' ${TERRAFORM_BACKEND_STACK_LOG_PATH} ; then \
		echo "Attempting to create Terraform Backend stack - '${TERRAFORM_BACKEND_STACK_NAME}' ..." ; \
			aws cloudformation deploy \
			--stack-name "${TERRAFORM_BACKEND_STACK_NAME}" \
			--template-file "${TERRAFORM_BACKEND_CFN_PATH}" \
			--parameter-overrides AppName="${APP_NAME}" Environment="${STAGE}" ; \
	elif grep CreationTime ${TERRAFORM_BACKEND_STACK_LOG_PATH} && grep CREATE_COMPLETE ${TERRAFORM_BACKEND_STACK_LOG_PATH} ; then \
		echo "Stack exists - '${TERRAFORM_BACKEND_STACK_NAME}'" ; \
	else \
		echo "Error creating stack!" ; \
		cat ${TERRAFORM_BACKEND_STACK_LOG_PATH} ;\
	fi


# terraform providers lock - is very important, it generates a lock file to all platforms
infra-init: validate validate-TERRAFORM_LIVE_DIR validate-TERRAFORM_BACKENDTPL_PATH validate-TERRAFORM_BINARY ## Prepare for creating a plan with terraform (init)
	@cd $(TERRAFORM_LIVE_DIR) && \
		${TERRAFORM_BINARY} init -backend-config="${TERRAFORM_BACKENDTPL_PATH}"
	@if [[ -n "${CI}" ]]; then \
		cd $(TERRAFORM_LIVE_DIR) ; \
		${TERRAFORM_BINARY} providers lock -platform=linux_amd64 ; \
	fi


infra-plan: validate validate-TERRAFORM_PLAN_PATH validate-TERRAFORM_PLAN_LOG_PATH ## Generate a Plan with terraform
	@[[ -f ${TERRAFORM_PLAN_PATH} ]] && rm ${TERRAFORM_PLAN_PATH}
	@[[ -f ${TERRAFORM_PLAN_LOG_PATH} ]] && rm ${TERRAFORM_PLAN_LOG_PATH}
	@cd $(TERRAFORM_LIVE_DIR) && ${TERRAFORM_BINARY} plan -out "${TERRAFORM_PLAN_PATH}" | tee ${TERRAFORM_PLAN_LOG_PATH}
	@if grep 'found no differences, so no changes are needed' ${TERRAFORM_PLAN_LOG_PATH} ; then \
		[[ -f ${TERRAFORM_PLAN_PATH} ]] && rm ${TERRAFORM_PLAN_PATH} ; \
		[[ "${CI}" = "true" ]] && echo "::warning file=Makefile:: Skipped infra-plan" ; \
		exit 0 ; \
	else \
		exit 0 ; \
	fi


infra-apply: validate validate-TERRAFORM_LIVE_DIR validate-TERRAFORM_PLAN_PATH validate-TERRAFORM_BINARY ## Apply plan with terraform
	@[[ -f ${TERRAFORM_APPLY_LOG_PATH} ]] && rm ${TERRAFORM_APPLY_LOG_PATH}
	@cd $(TERRAFORM_LIVE_DIR) && \
	if [[ ! -s ${TERRAFORM_PLAN_PATH} ]] ; then \
		echo Skipped apply ; \
		exit 0 ; \
	else \
		${TERRAFORM_BINARY} apply "${TERRAFORM_PLAN_PATH}" 2>&1 | tee ${TERRAFORM_APPLY_LOG_PATH} ; \
	fi
	@if [[ -s ${TERRAFORM_APPLY_LOG_PATH} ]] && grep 'Apply complete' ${TERRAFORM_APPLY_LOG_PATH} ; then \
		echo Successfully applied plan ; \
		exit 0 ; \
	else \
		echo Failed to apply plan ; \
		exit 1 ; \
	fi


infra-print-outputs: ## Print infra outputs with terraform
	@cd $(TERRAFORM_LIVE_DIR) && terraform output ${EXTRA_ARGS}
