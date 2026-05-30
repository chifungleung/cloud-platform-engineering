#!/usr/bin/env bash
# Walks up from a given stack path to find the nearest account.hcl
# and prints the account_id value. Used by CI workflows.
#
# Usage: ./scripts/get-account-id.sh <stack-path>
# Example: ./scripts/get-account-id.sh terraform/live/aws/dev/public-web-app-dev-01/us-east-1/vpc

set -euo pipefail

STACK_PATH="${1:?Usage: $0 <stack-path>}"
DIR="$STACK_PATH"

while [ "$DIR" != "." ] && [ "$DIR" != "/" ]; do
  if [ -f "$DIR/account.hcl" ]; then
    grep 'account_id' "$DIR/account.hcl" \
      | grep -oP '"[0-9]{12}"' \
      | tr -d '"'
    exit 0
  fi
  DIR=$(dirname "$DIR")
done

echo "ERROR: no account.hcl found above $STACK_PATH" >&2
exit 1
