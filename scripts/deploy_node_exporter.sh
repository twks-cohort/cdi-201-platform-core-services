#!/usr/bin/env bash
set -e

export CLUSTER=$1
export NODE_EXPORTER_CHART_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .node_exporter_chart_version)

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm repo update
helm upgrade --install nodeexporter prometheus-community/prometheus-node-exporter -n kube-system --set service.port=$NODE_EXPORTER_PORT
