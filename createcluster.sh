#!/bin/bash

set -euo pipefail

function latest_cluster_version() {
  gcloud container get-server-config --zone us-west1-a 2>/dev/null | yq .validMasterVersions[0] -r
}

gcloud container clusters create contour-test \
  --zone us-west1-a \
  --machine-type=n1-standard-4 \
  --num-nodes 5 \
  --enable-network-policy \
  --labels team=cf-k8s-networking,ephemeral=true \
  --cluster-version=$(latest_cluster_version)
