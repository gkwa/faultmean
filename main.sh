#!/bin/bash

set -e
set -x

. ./secrets/velero/vars.sh

# velero backup kind cluster

kind create cluster --name faultmean
kubectl config use-context kind-faultmean

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.6.0 \
    --bucket "$BUCKET" \
    --backup-location-config region="$REGION" \
    --snapshot-location-config region="$REGION" \
    --secret-file ./secrets/velero/credentials-velero
