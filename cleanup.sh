#!/bin/bash

export PAGER=cat
#set -e

. secrets/velero/vars.sh
set -u

aws iam delete-access-key --access-key-id "$AWS_ACCESS_KEY_ID" --user-name "$USERNAME"
aws iam delete-user-policy --user-name "$USERNAME" --policy-name "$POLICY_NAME"
aws iam delete-user --user-name "$USERNAME"
aws s3 rb --force --region "$REGION" "s3://$BUCKET"
