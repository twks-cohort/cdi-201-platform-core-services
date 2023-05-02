#!/usr/bin/env bash
set -e

export CLUSTER=$1
export DESIRED_METRICS_SERVER_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .metrics_server_version)

echo "validate core services"
bats test
