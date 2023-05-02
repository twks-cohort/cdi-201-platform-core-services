#!/usr/bin/env bash
set -e

kubectl create namespace grafana-system --dry-run=client -o yaml | kubectl apply -f -
