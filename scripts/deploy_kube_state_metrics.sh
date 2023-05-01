#!/usr/bin/env bash
set -e

export CLUSTER=$1
export KUBE_STATE_METRICS_CHART_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .kube_state_metrics_chart_version)

# prometheus.io recently took over ownership of the kube-state-metrics chart.

# cat <<EOF > kube-state-metrics/cluster-role-binding.yaml
# ---
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   labels:
#     app.kubernetes.io/component: exporter
#     app.kubernetes.io/name: kube-state-metrics
#     app.kubernetes.io/version: ${KUBE_STATE_METRICS_VERSION}
#   name: kube-state-metrics
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: kube-state-metrics
# subjects:
# - kind: ServiceAccount
#   name: kube-state-metrics
#   namespace: kube-system
# EOF

# cat <<EOF > kube-state-metrics/cluster-role.yaml
# ---
# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRole
# metadata:
#   labels:
#     app.kubernetes.io/component: exporter
#     app.kubernetes.io/name: kube-state-metrics
#     app.kubernetes.io/version: ${KUBE_STATE_METRICS_VERSION}
#   name: kube-state-metrics
# rules:
# - apiGroups:
#   - ""
#   resources:
#   - configmaps
#   - secrets
#   - nodes
#   - pods
#   - services
#   - resourcequotas
#   - replicationcontrollers
#   - limitranges
#   - persistentvolumeclaims
#   - persistentvolumes
#   - namespaces
#   - endpoints
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - apps
#   resources:
#   - statefulsets
#   - daemonsets
#   - deployments
#   - replicasets
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - batch
#   resources:
#   - cronjobs
#   - jobs
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - autoscaling
#   resources:
#   - horizontalpodautoscalers
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - authentication.k8s.io
#   resources:
#   - tokenreviews
#   verbs:
#   - create
# - apiGroups:
#   - authorization.k8s.io
#   resources:
#   - subjectaccessreviews
#   verbs:
#   - create
# - apiGroups:
#   - policy
#   resources:
#   - poddisruptionbudgets
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - certificates.k8s.io
#   resources:
#   - certificatesigningrequests
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - storage.k8s.io
#   resources:
#   - storageclasses
#   - volumeattachments
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - admissionregistration.k8s.io
#   resources:
#   - mutatingwebhookconfigurations
#   - validatingwebhookconfigurations
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - networking.k8s.io
#   resources:
#   - networkpolicies
#   - ingresses
#   verbs:
#   - list
#   - watch
# - apiGroups:
#   - coordination.k8s.io
#   resources:
#   - leases
#   verbs:
#   - list
#   - watch
# EOF

# cat <<EOF > kube-state-metrics/deployment.yaml
# ---
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   labels:
#     app.kubernetes.io/component: exporter
#     app.kubernetes.io/name: kube-state-metrics
#     app.kubernetes.io/version: ${KUBE_STATE_METRICS_VERSION}
#   name: kube-state-metrics
#   namespace: kube-system
# spec:
#   replicas: 1
#   selector:
#     matchLabels:
#       app.kubernetes.io/name: kube-state-metrics
#   template:
#     metadata:
#       labels:
#         app.kubernetes.io/component: exporter
#         app.kubernetes.io/name: kube-state-metrics
#         app.kubernetes.io/version: ${KUBE_STATE_METRICS_VERSION}
#     spec:
#       automountServiceAccountToken: true
#       containers:
#       - image: k8s.gcr.io/kube-state-metrics/kube-state-metrics:v${KUBE_STATE_METRICS_VERSION}
#         livenessProbe:
#           httpGet:
#             path: /healthz
#             port: 8080
#           initialDelaySeconds: 5
#           timeoutSeconds: 5
#         name: kube-state-metrics
#         ports:
#         - containerPort: 8080
#           name: http-metrics
#         - containerPort: 8081
#           name: telemetry
#         readinessProbe:
#           httpGet:
#             path: /
#             port: 8081
#           initialDelaySeconds: 5
#           timeoutSeconds: 5
#         securityContext:
#           runAsUser: 65534
#       nodeSelector:
#         kubernetes.io/os: linux
#       serviceAccountName: kube-state-metrics

# EOF

# cat <<EOF > kube-state-metrics/service-account.yaml
# ---
# apiVersion: v1
# automountServiceAccountToken: false
# kind: ServiceAccount
# metadata:
#   labels:
#     app.kubernetes.io/component: exporter
#     app.kubernetes.io/name: kube-state-metrics
#     app.kubernetes.io/version: ${KUBE_STATE_METRICS_VERSION}
#   name: kube-state-metrics
#   namespace: kube-system
# EOF

# cat <<EOF > kube-state-metrics/service.yaml
# ---
# apiVersion: v1
# kind: Service
# metadata:
#   labels:
#     app.kubernetes.io/component: exporter
#     app.kubernetes.io/name: kube-state-metrics
#     app.kubernetes.io/version: ${KUBE_STATE_METRICS_VERSION}
#   name: kube-state-metrics
#   namespace: kube-system
# spec:
#   clusterIP: None
#   ports:
#   - name: http-metrics
#     port: 8080
#     targetPort: http-metrics
#   - name: telemetry
#     port: 8081
#     targetPort: telemetry
#   selector:
#     app.kubernetes.io/name: kube-state-metrics
# EOF

# kubectl apply -f kube-state-metrics/ --recursive


helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm upgrade kube-state-metrics prometheus-community/kube-state-metrics --install --version=$KUBE_STATE_METRICS_CHART_VERSION --namespace=kube-system
