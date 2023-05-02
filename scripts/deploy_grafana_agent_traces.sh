#!/usr/bin/env bash
set -e

export CLUSTER=$1
export NAMESPACE=grafana-system

cat <<EOF > grafana-agent/traces-exporter.yaml

kind: ConfigMap
metadata:
  name: grafana-agent-traces
  namespace: ${NAMESPACE}
apiVersion: v1
data:
  agent.yaml: |
    traces:
      configs:
        - batch:
            send_batch_size: 1000
            timeout: 5s
          name: default
          receivers:
            jaeger:
              protocols:
                grpc: null
                thrift_binary: null
                thrift_compact: null
                thrift_http: null
              remote_sampling:
                strategy_file: /etc/agent/strategies.json
                tls:
                  insecure: true
            opencensus: null
            otlp:
              protocols:
                grpc: null
                http: null
            zipkin: null
          remote_write:
            - basic_auth:
                password: $GRAFANA_METRICS_API_KEY
                username: $GRAFANA_STACK_TRACES_USERNAME
              endpoint: $GRAFANA_STACK_TRACES_ENDPOINT
              retry_on_failure:
                enabled: false
          scrape_configs:
            - bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
              job_name: kubernetes-pods
              kubernetes_sd_configs:
                - role: pod
              relabel_configs:
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
              tls_config:
                ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
                insecure_skip_verify: false
  strategies.json: '{"default_strategy": {"param": 0.001, "type": "probabilistic"}}'

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: grafana-agent-traces
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: grafana-agent-traces
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
  name: grafana-agent-traces
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: grafana-agent-traces
subjects:
- kind: ServiceAccount
  name: grafana-agent-traces
  namespace: ${NAMESPACE}
---
apiVersion: v1
kind: Service
metadata:
  labels:
    name: grafana-agent-traces
  name: grafana-agent-traces
  namespace: ${NAMESPACE}
spec:
  ports:
  - name: grafana-agent-traces-http-metrics
    port: 80
    targetPort: 80
  - name: grafana-agent-traces-thrift-compact
    port: 6831
    protocol: UDP
    targetPort: 6831
  - name: grafana-agent-traces-thrift-binary
    port: 6832
    protocol: UDP
    targetPort: 6832
  - name: grafana-agent-traces-thrift-http
    port: 14268
    protocol: TCP
    targetPort: 14268
  - name: grafana-agent-traces-thrift-grpc
    port: 14250
    protocol: TCP
    targetPort: 14250
  - name: grafana-agent-traces-zipkin
    port: 9411
    protocol: TCP
    targetPort: 9411
  - name: grafana-agent-traces-otlp-grpc
    port: 4317
    protocol: TCP
    targetPort: 4317
  - name: grafana-agent-traces-otlp-http
    port: 4318
    protocol: TCP
    targetPort: 4318
  - name: grafana-agent-traces-opencensus
    port: 55678
    protocol: TCP
    targetPort: 55678
  selector:
    name: grafana-agent-traces
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-agent-traces
  namespace: ${NAMESPACE}
spec:
  minReadySeconds: 10
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      name: grafana-agent-traces
  template:
    metadata:
      labels:
        name: grafana-agent-traces
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
        name: grafana-agent-traces
        ports:
        - containerPort: 80
          name: http-metrics
        - containerPort: 6831
          name: thrift-compact
          protocol: UDP
        - containerPort: 6832
          name: thrift-binary
          protocol: UDP
        - containerPort: 14268
          name: thrift-http
          protocol: TCP
        - containerPort: 14250
          name: thrift-grpc
          protocol: TCP
        - containerPort: 9411
          name: zipkin
          protocol: TCP
        - containerPort: 4317
          name: otlp-grpc
          protocol: TCP
        - containerPort: 4318
          name: otlp-http
          protocol: TCP
        - containerPort: 55678
          name: opencensus
          protocol: TCP
        volumeMounts:
        - mountPath: /etc/agent
          name: grafana-agent-traces
      serviceAccountName: grafana-agent-traces
      volumes:
      - configMap:
          name: grafana-agent-traces
        name: grafana-agent-traces

EOF

kubectl apply -f grafana-agent/traces-exporter.yaml
