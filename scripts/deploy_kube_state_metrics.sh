#!/usr/bin/env bash
set -e

export CLUSTER=$1
export KUBE_STATE_METRICS_CHART_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .kube_state_metrics_chart_version)

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade kube-state-metrics prometheus-community/kube-state-metrics --install --version=$KUBE_STATE_METRICS_CHART_VERSION --namespace=kube-system
