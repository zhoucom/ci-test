#!/bin/bash
set -e

# ==============================================================================
# Script: manual_checkout.sh
# Purpose: Manually checkout code from Git without using Jenkins Git Plugin.
# Usage: ./manual_checkout.sh <REPO_URL> <BRANCH> [GIT_TOKEN]
# ==============================================================================

REPO_URL="$1"
BRANCH="$2"
GIT_TOKEN="$3"

if [ -z "$REPO_URL" ] || [ -z "$BRANCH" ]; then
    echo "Error: REPO_URL and BRANCH are required."
    echo "Usage: $0 <REPO_URL> <BRANCH> [GIT_TOKEN]"
    exit 1
fi

echo "--------------------------------------------------------"
echo "Starting Manual Checkout..."
echo "Repo: $REPO_URL"
echo "Branch: $BRANCH"
echo "--------------------------------------------------------"

# Remove existing files to ensure a clean build
# equivalent to ws-cleanup plugin
echo "Cleaning workspace..."
rm -rf ./* ./.git

# Construct Auth URL if token is provided
if [ -n "$GIT_TOKEN" ]; then
    # Insert token into URL: https://TOKEN@github.com/...
    # Assumes valid https URL structure
    AUTH_REPO_URL="${REPO_URL/https:\/\//https:\/\/$GIT_TOKEN@}"
    echo "Checking out with token authentication..."
else
    AUTH_REPO_URL="$REPO_URL"
    echo "Checking out with existing agent credentials (ssh/https)..."
fi

# Clone specific branch with depth 1 for speed (shallow clone)
git clone --depth 1 --branch "$BRANCH" "$AUTH_REPO_URL" .

if [ $? -eq 0 ]; then
    echo "Checkout successful."
    # Show last commit info
    git log -1 --format="Commit: %h - %s (%an)"
else
    echo "Checkout failed!"
    exit 1
fi
