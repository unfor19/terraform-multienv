#!/bin/bash
_LIVE_DIR=${LIVE_DIR:=live}
_BACKEND_TPL_PATH=${BACKEND_TPL_PATH:=backend.tf.tpl}

if [[ ! -d "$_LIVE_DIR" ]]; then
    if [[ ! -f "${_LIVE_DIR}/${_BACKEND_TPL_PATH}" ]]; then
        echo "[ERROR] The file backend.tf.tpl doesn't exist - $_BACKEND_TPL_PATH"
        exit
    fi
else
    echo "[ERROR] The supplied live directory doesn't exist - $_LIVE_DIR"
    exit
fi

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
cp "${_LIVE_DIR}"/* "${BRANCH_NAME}"/
sed -i.bak 's~AWS_REGION~'"$AWS_REGION"'~' "${BRANCH_NAME}/${_BACKEND_TPL_PATH}"
sed -i.bak 's~APP_NAME~'"$TF_VAR_app_name"'~' "${BRANCH_NAME}/${_BACKEND_TPL_PATH}"
sed -i.bak 's~ENVIRONMENT~'"$BRANCH_NAME"'~' "${BRANCH_NAME}/${_BACKEND_TPL_PATH}"
mv "${BRANCH_NAME}/${_BACKEND_TPL_PATH}" "${BRANCH_NAME}"/backend.tf
echo "[LOG] Prepared files and folders for the environment - $BRANCH_NAME"
ls -lah "$BRANCH_NAME"
cat "${BRANCH_NAME}"/backend.tf
