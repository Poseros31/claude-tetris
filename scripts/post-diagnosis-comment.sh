#!/usr/bin/env bash
#
# Posts (or updates) the automated diagnosis comment on a GitHub issue.
# Usage: ./scripts/post-diagnosis-comment.sh "<diagnosis text>"
#
# The issue number is read from the workflow event payload, and the comment
# is edited in place (via --edit-last) on repeat runs instead of piling up
# a new comment on every issue edit.
#

set -euo pipefail

ISSUE=$(jq -r '.issue.number // empty' "${GITHUB_EVENT_PATH:?GITHUB_EVENT_PATH not set}")
if ! [[ "$ISSUE" =~ ^[0-9]+$ ]]; then
  echo "Error: no issue number in event payload" >&2
  exit 1
fi

BODY="${1:?Usage: post-diagnosis-comment.sh <diagnosis text>}"

gh issue comment "$ISSUE" --edit-last --create-if-none --body "$BODY"
