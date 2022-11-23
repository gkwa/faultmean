#!/bin/bash

# https://github.com/vmware-tanzu/velero-plugin-for-aws#setup

set -e
set -u
set -x

export PAGER=cat

if ! command -v jq >/dev/null; then
    echo cant find jq, exiting
    exit 1
fi

TIMESTAMP="$(date +%s)"

[[ -d secrets/velero ]] && mv secrets/velero "secrets/velero.$TIMESTAMP"
mkdir -p secrets/velero
printf 'TIMESTAMP=%s\n' "$TIMESTAMP" >>secrets/velero/vars.sh

BUCKET=kubernetes-velero-backup-test
printf 'BUCKET=%s\n' "$BUCKET" >>secrets/velero/vars.sh

USERNAME=velero_kubernetes_backup
printf 'USERNAME=%s\n' "$USERNAME" >>secrets/velero/vars.sh

POLICY_NAME="$USERNAME"
printf 'POLICY_NAME=%s\n' "$POLICY_NAME" >>secrets/velero/vars.sh

REGION=us-west-2
printf 'REGION=%s\n' "$REGION" >>secrets/velero/vars.sh

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
aws iam create-user --user-name "$USERNAME"
aws iam create-access-key --user-name "$USERNAME" >"secrets/velero/$USERNAME.json"

AWS_ACCESS_KEY_ID="$(jq -r .AccessKey.AccessKeyId secrets/velero/$USERNAME.json)"
AWS_SECRET_ACCESS_KEY="$(jq -r .AccessKey.SecretAccessKey secrets/velero/$USERNAME.json)"
printf '[default]\naws_access_key_id=%s\naws_secret_access_key=%s\n' "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY" >"secrets/velero/credentials-velero"

printf 'AWS_ACCESS_KEY_ID=%s\n' "$AWS_ACCESS_KEY_ID" >>secrets/velero/vars.sh

cat >secrets/velero/velero-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}"
            ]
        }
    ]
}
EOF

aws iam put-user-policy --user-name "$USERNAME" --policy-name "$POLICY_NAME" --policy-document file://secrets/velero/velero-policy.json
