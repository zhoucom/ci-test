#!/bin/bash
set -e

# ==============================================================================
# Script: update_github_status.sh
# Purpose: Manually update GitHub Commit Status using Curl.
# Usage: ./update_github_status.sh <REPO_SLUG> <COMMIT_SHA> <STATE> <DESCRIPTION> <TOKEN>
#
# Arguments:
#   REPO_SLUG:   "owner/repo", e.g., "zhoucom/jenkins-springboot"
#   COMMIT_SHA:  The full 40-char SHA of the commit.
#   STATE:       pending | success | failure | error
#   DESCRIPTION: A short description string.
#   TOKEN:       GitHub PAT (Optional if present in GIT_TOKEN env var)
# ==============================================================================

REPO_SLUG="$1"
COMMIT_SHA="$2"
STATE="$3"
DESCRIPTION="$4"
TOKEN="${5:-$GIT_TOKEN}" # Use argument 5, default to env GIT_TOKEN

if [ -z "$REPO_SLUG" ] || [ -z "$COMMIT_SHA" ] || [ -z "$STATE" ] || [ -z "$DESCRIPTION" ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <REPO_SLUG> <COMMIT_SHA> <STATE> <DESCRIPTION> [TOKEN]"
    exit 1
fi

if [ -z "$TOKEN" ]; then
    echo "Error: No Git Token provided (arg 5 or GIT_TOKEN env var)."
    exit 1
fi

API_URL="https://api.github.com/repos/${REPO_SLUG}/statuses/${COMMIT_SHA}"

echo "Updating GitHub Status..."
echo "  Repo: $REPO_SLUG"
echo "  SHA:  ${COMMIT_SHA:0:7}"
echo "  State: $STATE"
echo "  Desc:  $DESCRIPTION"

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "$API_URL" \
  -d "{
    \"state\":\"$STATE\",
    \"target_url\":\"http://localhost:8081/job/native-pipeline\", 
    \"description\":\"$DESCRIPTION\",
    \"context\":\"Jenkins/Build\"
  }"

echo "" # Newline after curl
