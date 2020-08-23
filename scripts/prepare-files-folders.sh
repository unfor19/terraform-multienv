#!/bin/bash
DRONE_BRANCH=$(git branch --show-current)
[[ -d "$DRONE_BRANCH" ]] && rm -r "$DRONE_BRANCH"
mkdir -p "${DRONE_BRANCH}/"
cp live/*."${DRONE_BRANCH}" "${DRONE_BRANCH}/"
cp live/*.tf "${DRONE_BRANCH}/"
cp live/*.tpl "${DRONE_BRANCH}/" 2>/dev/null || true
mv "${DRONE_BRANCH}/backend.tf.${DRONE_BRANCH}" "${DRONE_BRANCH}/backend.tf"
