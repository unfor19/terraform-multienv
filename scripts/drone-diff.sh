#!/bin/bash
_GIT_DIFF=$(git diff --numstat HEAD HEAD~1)
_NUM_LINES=$(echo "$_GIT_DIFF" | wc -l)

if [[ "$_NUM_LINES" -eq 1 ]]; then
    README_ONLY=$(echo "$_GIT_DIFF" | grep README\.md)
    if [[ -n "$README_ONLY" ]]; then
        echo "[LOG] Only README.md was changed, skipping pipeline"
        exit 78
    fi
fi
echo "[LOG] Files that were changed in this commit"
echo "$_GIT_DIFF" | awk '{print $3}'
