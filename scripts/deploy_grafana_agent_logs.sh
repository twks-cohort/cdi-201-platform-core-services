#!/usr/bin/env bash
set -e

export CLUSTER=$1
export NAMESPACE=grafana-system

cat <<EOF > grafana-agent/logs-exporter.yaml

kind: ConfigMap
metadata:
  name: grafana-agent-logs
  namespace: ${NAMESPACE}
apiVersion: v1
data:
  agent.yaml: |
    metrics:
      wal_directory: /tmp/grafana-agent-wal
      global:
        scrape_interval: 60s
        external_labels:
          cluster: $CLUSTER
      configs:
      - name: integrations
        remote_write:
        - url: $GRAFANA_STACK_METRICS_ENDPOINT
          basic_auth:
            username: $GRAFANA_STACK_METRICS_USERNAME
            password: $GRAFANA_METRICS_API_KEY
    integrations:
      prometheus_remote_write:
      - url: $GRAFANA_STACK_METRICS_ENDPOINT
        basic_auth:
          username: $GRAFANA_STACK_METRICS_USERNAME
          password: $GRAFANA_METRICS_API_KEY

    logs:
      configs:
      - name: integrations
        clients:
        - url: $GRAFANA_STACK_LOGS_ENDPOINT
          basic_auth:
            username: $GRAFANA_STACK_LOGS_USERNAME
            password: $GRAFANA_METRICS_API_KEY
          external_labels:
            cluster: $CLUSTER
        positions:
          filename: /tmp/positions.yaml
        target_config:
          sync_period: 10s
        scrape_configs:
        - job_name: integrations/kubernetes/pod-logs
          kubernetes_sd_configs:
            - role: pod
          pipeline_stages:
            - docker: {}
          relabel_configs:
            - source_labels:
                - __meta_kubernetes_pod_node_name
              target_label: __host__
            - action: labelmap
              regex: __meta_kubernetes_pod_label_(.+)
            - action: replace
              replacement: \$1
              separator: /
              source_labels:
                - __meta_kubernetes_namespace
                - __meta_kubernetes_pod_name
              target_label: job
            - action: replace
              source_labels:
                - __meta_kubernetes_namespace
              target_label: namespace
            - action: replace
              source_labels:
                - __meta_kubernetes_pod_name
              target_label: pod
            - action: replace
              source_labels:
                - __meta_kubernetes_pod_container_name
              target_label: container
            - replacement: /var/log/pods/*\$1*/\$2/*.log
              regex: "(.*)/(.*)"
              separator: /
              source_labels:
                - __meta_kubernetes_pod_name
                - __meta_kubernetes_pod_container_name
              target_label: __path__

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana-agent-logs
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: grafana-agent-logs
rules:
- apiGroups:
  - ""
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  - events
  verbs:
  - get
  - list
  - watch
- nonResourceURLs:
  - /metrics
  verbs:
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: grafana-agent-logs
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: grafana-agent-logs
subjects:
- kind: ServiceAccount
  name: grafana-agent-logs
  namespace: ${NAMESPACE}
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: grafana-agent-logs
  namespace: ${NAMESPACE}
spec:
  minReadySeconds: 10
  selector:
    matchLabels:
      name: grafana-agent-logs
  template:
    metadata:
      labels:
        name: grafana-agent-logs
    spec:
      containers:
      - args:
        - -config.expand-env=true
        - -config.file=/etc/agent/agent.yaml
        - -server.http.address=0.0.0.0:80
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        image: grafana/agent:v0.32.1
        imagePullPolicy: IfNotPresent
        name: grafana-agent-logs
        ports:
        - containerPort: 8080
          name: http-metrics
        securityContext:
          privileged: true
          runAsUser: 0
        volumeMounts:
        - mountPath: /etc/agent
          name: grafana-agent-logs
        - mountPath: /var/log
          name: varlog
        - mountPath: /var/lib/docker/containers
          name: varlibdockercontainers
          readOnly: true
      serviceAccountName: grafana-agent-logs
      tolerations:
      - effect: NoSchedule
        operator: Exists
      volumes:
      - configMap:
          name: grafana-agent-logs
        name: grafana-agent-logs
      - hostPath:
          path: /var/log
        name: varlog
      - hostPath:
          path: /var/lib/docker/containers
        name: varlibdockercontainers
  updateStrategy:
    type: RollingUpdate

EOF

kubectl apply -f grafana-agent/logs-exporter.yaml
