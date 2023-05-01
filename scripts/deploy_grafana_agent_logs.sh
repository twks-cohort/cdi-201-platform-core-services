#!/usr/bin/env bash
set -e

export CLUSTER=$1
export NAMESPACE=lab-system

cat <<EOF > grafana-agent/logs-exporter.yaml

EOF
