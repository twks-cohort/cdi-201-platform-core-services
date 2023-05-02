#!/usr/bin/env bats

@test "validate metrics-server version" {
  run bash -c "kubectl get deployment metrics-server -n kube-system -o json | grep $DESIRED_METRICS_SERVER_VERSION"
  [[ "${output}" =~ "metrics-server" ]]
}

@test "validate metrics-server status" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'metrics-server'"
  [[ "${output}" =~ "Running" ]]
}

@test "validate kube-state-metrics status" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'kube-state-metrics'"
  [[ "${output}" =~ "Running" ]]
}

@test "validate node-exporter status" {
  run bash -c "kubectl get po -n kube-system -o wide | grep 'node-exporter'"
  [[ "${output}" =~ "Running" ]]
}

@test "validate grafana-agent metrics status" {
  run bash -c "kubectl get po -n grafana-system -o wide | grep 'grafana-agent-0'"
  [[ "${output}" =~ "Running" ]]
}

@test "validate grafana-agent logs status" {
  run bash -c "kubectl get po -n grafana-system -o wide | grep 'grafana-agent-logs'"
  [[ "${output}" =~ "Running" ]]
}
