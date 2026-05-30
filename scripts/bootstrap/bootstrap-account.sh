#!/usr/bin/env bash
# One-time bootstrap: creates S3 state bucket and DynamoDB lock table in an account.
# Run this manually once per account before using Terragrunt.
#
# Usage: ./bootstrap-account.sh <account-id> <region> <aws-profile>

set -euo pipefail

ACCOUNT_ID="${1:?Usage: $0 <account-id> <region> <aws-profile>}"
REGION="${2:?Usage: $0 <account-id> <region> <aws-profile>}"
PROFILE="${3:?Usage: $0 <account-id> <region> <aws-profile>}"

BUCKET="tf-state-${ACCOUNT_ID}"
TABLE="tf-locks-${ACCOUNT_ID}"

echo "Bootstrapping account ${ACCOUNT_ID} in ${REGION} using profile ${PROFILE}"

# Create S3 bucket
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  $([ "$REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$REGION") \
  --profile "$PROFILE"

aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled \
  --profile "$PROFILE"

aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' \
  --profile "$PROFILE"

aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --profile "$PROFILE"

echo "S3 bucket ${BUCKET} created."

# Create DynamoDB table
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" \
  --profile "$PROFILE"

echo "DynamoDB table ${TABLE} created."
echo "Bootstrap complete for account ${ACCOUNT_ID}."
