#!/usr/bin/env bash
set -e

export CLUSTER=$1
export NAMESPACE=grafana-system

cat <<EOF > grafana-agent/events-exporter.yaml

kind: ConfigMap
metadata:
  name: grafana-agent
  namespace: ${NAMESPACE}
apiVersion: v1
data:
  agent.yaml: |
    metrics:
      wal_directory: /var/lib/agent/wal
      global:
        scrape_interval: 60s
        external_labels:
          cluster: ${CLUSTER}
      configs:
      - name: integrations
        remote_write:
        - url: ${GRAFANA_STACK_METRICS_ENDPOINT}
          basic_auth:
            username: ${GRAFANA_STACK_METRICS_USERNAME}
            password: ${GRAFANA_METRICS_API_KEY}
        scrape_configs: []
    integrations:
      eventhandler:
        cache_path: /var/lib/agent/eventhandler.cache
        logs_instance: integrations
    logs:
      configs:
      - name: integrations
        clients:
        - url: $GRAFANA_STACK_LOGS_ENDPOINT
          basic_auth:
            username: $GRAFANA_STACK_LOGS_USERNAME
            password: $GRAFANA_METRICS_API_KEY
          external_labels:
            cluster: ${CLUSTER}
            job: integrations/kubernetes/eventhandler
        positions:
          filename: /tmp/positions.yaml
        target_config:
          sync_period: 10s
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana-agent
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: grafana-agent
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
  name: grafana-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: grafana-agent
subjects:
- kind: ServiceAccount
  name: grafana-agent
  namespace: ${NAMESPACE}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    name: grafana-agent
  name: grafana-agent
  namespace: ${NAMESPACE}
spec:
  clusterIP: None
  ports:
  - name: grafana-agent-http-metrics
    port: 80
    targetPort: 80
  selector:
    name: grafana-agent
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: grafana-agent
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      name: grafana-agent
  serviceName: grafana-agent
  template:
    metadata:
      labels:
        name: grafana-agent
    spec:
      containers:
      - args:
        - -config.expand-env=true
        - -config.file=/etc/agent/agent.yaml
        - -enable-features=integrations-next
        - -server.http.address=0.0.0.0:80
        env:
        - name: HOSTNAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        image: grafana/agent:v0.32.1
        imagePullPolicy: IfNotPresent
        name: grafana-agent
        ports:
        - containerPort: 80
          name: http-metrics
        volumeMounts:
        - mountPath: /var/lib/agent
          name: agent-wal
        - mountPath: /etc/agent
          name: grafana-agent
      serviceAccountName: grafana-agent
      volumes:
      - configMap:
          name: grafana-agent
        name: grafana-agent
  updateStrategy:
    type: RollingUpdate
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: agent-wal
      namespace: ${NAMESPACE}
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi

EOF

kubectl apply -f grafana-agent/events-exporter.yaml
