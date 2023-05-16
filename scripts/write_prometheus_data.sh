#!/usr/bin/env bash
set -e

export CLUSTER=$1

prom_endpoint=$(kubectl get svc -n monitoring ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' )
opw write team##-201-platform-vcluster prometheus_endpoint $prom_endpoint
