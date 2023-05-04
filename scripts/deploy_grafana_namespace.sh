#!/usr/bin/env bash
set -e

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: grafana-system
EOF
