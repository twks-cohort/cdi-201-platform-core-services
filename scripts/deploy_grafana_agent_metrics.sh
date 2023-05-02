#!/usr/bin/env bash
set -e

export CLUSTER=$1
export NAMESPACE=grafana-system
export GRAFANA_AGENT_VERSION=$(cat $CLUSTER.auto.tfvars.json | jq -r .grafana_agent_version)

cat <<EOF > grafana-agent/metrics-exporter.yaml
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
          cluster: $CLUSTER
      configs:
      - name: integrations
        remote_write:
        - url: $GRAFANA_STACK_METRICS_ENDPOINT
          basic_auth:
            username: $GRAFANA_STACK_METRICS_USERNAME
            password: $GRAFANA_METRICS_API_KEY
          send_exemplars: true
        scrape_configs:
          - job_name: integrations/kubernetes/cadvisor
            bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
            kubernetes_sd_configs:
              - role: node
            metric_relabel_configs:
              - source_labels: [__name__]
                regex: kube_pod_status_reason|kubelet_pod_start_duration_seconds_bucket|kube_horizontalpodautoscaler_status_current_replicas|kubelet_running_pod_count|cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits|namespace_memory:kube_pod_container_resource_limits:sum|kube_statefulset_metadata_generation|container_network_receive_packets_total|kube_persistentvolumeclaim_resource_requests_storage_bytes|kube_deployment_status_observed_generation|process_resident_memory_bytes|kube_job_status_active|namespace_memory:kube_pod_container_resource_requests:sum|kubelet_running_container_count|container_network_transmit_packets_dropped_total|container_fs_reads_total|node_namespace_pod_container:container_memory_cache|kubelet_running_containers|kube_pod_info|node_namespace_pod_container:container_memory_working_set_bytes|process_cpu_seconds_total|kube_pod_container_resource_limits|node_namespace_pod_container:container_memory_swap|kube_statefulset_status_current_revision|kube_resourcequota|container_fs_writes_total|container_cpu_cfs_throttled_periods_total|storage_operation_errors_total|kubelet_pleg_relist_duration_seconds_count|kube_daemonset_status_number_available|kube_statefulset_status_replicas|kube_pod_container_status_waiting_reason|kube_pod_container_resource_requests|kubelet_cgroup_manager_duration_seconds_count|rest_client_requests_total|kubernetes_build_info|container_network_receive_packets_dropped_total|container_memory_cache|kube_namespace_status_phase|kube_node_info|kube_statefulset_status_replicas_ready|kube_deployment_status_replicas_updated|node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile|kubelet_certificate_manager_client_expiration_renew_errors|kubelet_running_pods|kube_deployment_status_replicas_available|kube_replicaset_owner|node_filesystem_size_bytes|namespace_cpu:kube_pod_container_resource_requests:sum|kube_pod_owner|kube_statefulset_status_update_revision|kubelet_server_expiration_renew_errors|kube_node_status_capacity|kubelet_pod_start_duration_seconds_count|kube_horizontalpodautoscaler_spec_min_replicas|kube_horizontalpodautoscaler_status_desired_replicas|namespace_workload_pod:kube_pod_owner:relabel|kube_statefulset_status_observed_generation|kube_daemonset_status_desired_number_scheduled|namespace_workload_pod|container_cpu_usage_seconds_total|cluster:namespace:pod_memory:active:kube_pod_container_resource_limits|kubelet_node_name|kubelet_pod_worker_duration_seconds_bucket|kubelet_volume_stats_inodes_used|kube_statefulset_status_replicas_updated|container_memory_rss|kubelet_volume_stats_available_bytes|container_memory_swap|container_memory_working_set_bytes|kube_daemonset_status_number_misscheduled|container_fs_reads_bytes_total|namespace_cpu:kube_pod_container_resource_limits:sum|kube_deployment_metadata_generation|kube_horizontalpodautoscaler_spec_max_replicas|container_network_receive_bytes_total|go_goroutines|kubelet_node_config_error|kube_node_status_condition|node_filesystem_avail_bytes|container_cpu_cfs_periods_total|kube_deployment_spec_replicas|kubelet_runtime_operations_errors_total|machine_memory_bytes|container_network_transmit_packets_total|kubelet_volume_stats_capacity_bytes|storage_operation_duration_seconds_count|kubelet_pleg_relist_interval_seconds_bucket|kubelet_runtime_operations_total|kube_node_status_allocatable|kube_daemonset_status_updated_number_scheduled|kube_pod_status_phase|kube_statefulset_replicas|kubelet_certificate_manager_client_ttl_seconds|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|container_network_transmit_bytes_total|kubelet_cgroup_manager_duration_seconds_bucket|volume_manager_total_volumes|kube_daemonset_status_current_number_scheduled|kubelet_certificate_manager_server_ttl_seconds|container_fs_writes_bytes_total|kubelet_pod_worker_duration_seconds_count|node_namespace_pod_container:container_memory_rss|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|kubelet_pleg_relist_duration_seconds_bucket|kubelet_volume_stats_inodes|kube_job_failed|kube_job_status_start_time|kube_node_spec_taint|cluster:namespace:pod_memory:active:kube_pod_container_resource_requests|kube_namespace_status_phase|container_cpu_usage_seconds_total|kube_pod_status_phase|kube_pod_start_time|kube_pod_container_status_restarts_total|kube_pod_container_info|kube_pod_container_status_waiting_reason|kube_daemonset.*|kube_replicaset.*|kube_statefulset.*|kube_job.*|kube_node.*|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|namespace_cpu:kube_pod_container_resource_requests:sum|node_cpu.*|node_memory.*|node_filesystem.*
                action: keep
            relabel_configs:
              - replacement: kubernetes.default.svc.cluster.local:443
                target_label: __address__
              - regex: (.+)
                replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
                source_labels:
                  - __meta_kubernetes_node_name
                target_label: __metrics_path__
            scheme: https
            tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              insecure_skip_verify: true
              server_name: kubernetes
          - job_name: integrations/kubernetes/kubelet
            bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
            kubernetes_sd_configs:
              - role: node
            metric_relabel_configs:
              - source_labels: [__name__]
                regex: kube_pod_status_reason|kubelet_pod_start_duration_seconds_bucket|kube_horizontalpodautoscaler_status_current_replicas|kubelet_running_pod_count|cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits|namespace_memory:kube_pod_container_resource_limits:sum|kube_statefulset_metadata_generation|container_network_receive_packets_total|kube_persistentvolumeclaim_resource_requests_storage_bytes|kube_deployment_status_observed_generation|process_resident_memory_bytes|kube_job_status_active|namespace_memory:kube_pod_container_resource_requests:sum|kubelet_running_container_count|container_network_transmit_packets_dropped_total|container_fs_reads_total|node_namespace_pod_container:container_memory_cache|kubelet_running_containers|kube_pod_info|node_namespace_pod_container:container_memory_working_set_bytes|process_cpu_seconds_total|kube_pod_container_resource_limits|node_namespace_pod_container:container_memory_swap|kube_statefulset_status_current_revision|kube_resourcequota|container_fs_writes_total|container_cpu_cfs_throttled_periods_total|storage_operation_errors_total|kubelet_pleg_relist_duration_seconds_count|kube_daemonset_status_number_available|kube_statefulset_status_replicas|kube_pod_container_status_waiting_reason|kube_pod_container_resource_requests|kubelet_cgroup_manager_duration_seconds_count|rest_client_requests_total|kubernetes_build_info|container_network_receive_packets_dropped_total|container_memory_cache|kube_namespace_status_phase|kube_node_info|kube_statefulset_status_replicas_ready|kube_deployment_status_replicas_updated|node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile|kubelet_certificate_manager_client_expiration_renew_errors|kubelet_running_pods|kube_deployment_status_replicas_available|kube_replicaset_owner|node_filesystem_size_bytes|namespace_cpu:kube_pod_container_resource_requests:sum|kube_pod_owner|kube_statefulset_status_update_revision|kubelet_server_expiration_renew_errors|kube_node_status_capacity|kubelet_pod_start_duration_seconds_count|kube_horizontalpodautoscaler_spec_min_replicas|kube_horizontalpodautoscaler_status_desired_replicas|namespace_workload_pod:kube_pod_owner:relabel|kube_statefulset_status_observed_generation|kube_daemonset_status_desired_number_scheduled|namespace_workload_pod|container_cpu_usage_seconds_total|cluster:namespace:pod_memory:active:kube_pod_container_resource_limits|kubelet_node_name|kubelet_pod_worker_duration_seconds_bucket|kubelet_volume_stats_inodes_used|kube_statefulset_status_replicas_updated|container_memory_rss|kubelet_volume_stats_available_bytes|container_memory_swap|container_memory_working_set_bytes|kube_daemonset_status_number_misscheduled|container_fs_reads_bytes_total|namespace_cpu:kube_pod_container_resource_limits:sum|kube_deployment_metadata_generation|kube_horizontalpodautoscaler_spec_max_replicas|container_network_receive_bytes_total|go_goroutines|kubelet_node_config_error|kube_node_status_condition|node_filesystem_avail_bytes|container_cpu_cfs_periods_total|kube_deployment_spec_replicas|kubelet_runtime_operations_errors_total|machine_memory_bytes|container_network_transmit_packets_total|kubelet_volume_stats_capacity_bytes|storage_operation_duration_seconds_count|kubelet_pleg_relist_interval_seconds_bucket|kubelet_runtime_operations_total|kube_node_status_allocatable|kube_daemonset_status_updated_number_scheduled|kube_pod_status_phase|kube_statefulset_replicas|kubelet_certificate_manager_client_ttl_seconds|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|container_network_transmit_bytes_total|kubelet_cgroup_manager_duration_seconds_bucket|volume_manager_total_volumes|kube_daemonset_status_current_number_scheduled|kubelet_certificate_manager_server_ttl_seconds|container_fs_writes_bytes_total|kubelet_pod_worker_duration_seconds_count|node_namespace_pod_container:container_memory_rss|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|kubelet_pleg_relist_duration_seconds_bucket|kubelet_volume_stats_inodes|kube_job_failed|kube_job_status_start_time|kube_node_spec_taint|cluster:namespace:pod_memory:active:kube_pod_container_resource_requests|kube_namespace_status_phase|container_cpu_usage_seconds_total|kube_pod_status_phase|kube_pod_start_time|kube_pod_container_status_restarts_total|kube_pod_container_info|kube_pod_container_status_waiting_reason|kube_daemonset.*|kube_replicaset.*|kube_statefulset.*|kube_job.*|kube_node.*|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|namespace_cpu:kube_pod_container_resource_requests:sum|node_cpu.*|node_memory.*|node_filesystem.*
                action: keep
            relabel_configs:
              - replacement: kubernetes.default.svc.cluster.local:443
                target_label: __address__
              - regex: (.+)
                replacement: /api/v1/nodes/${1}/proxy/metrics
                source_labels:
                  - __meta_kubernetes_node_name
                target_label: __metrics_path__
            scheme: https
            tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              insecure_skip_verify: true
              server_name: kubernetes
          - job_name: istiod
            kubernetes_sd_configs:
            - namespaces:
                names:
                - istio-system
              role: endpoints
            relabel_configs:
            - action: keep
              regex: istiod;http-monitoring
              source_labels:
              - __meta_kubernetes_service_name
              - __meta_kubernetes_endpoint_port_name
          #- job_name: envoy-stats
          #  kubernetes_sd_configs:
          #  - role: pod
          #  metrics_path: /stats/prometheus
          #  relabel_configs:
          #  - action: keep
          #    regex: .*-envoy-prom
          #    source_labels:
          #    - __meta_kubernetes_pod_container_port_name
          - job_name: integrations/kubernetes/kube-state-metrics
            kubernetes_sd_configs:
              - role: pod
            metric_relabel_configs:
              - source_labels: [__name__]
                regex: kube_pod_status_reason|kubelet_pod_start_duration_seconds_bucket|kube_horizontalpodautoscaler_status_current_replicas|kubelet_running_pod_count|cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits|namespace_memory:kube_pod_container_resource_limits:sum|kube_statefulset_metadata_generation|container_network_receive_packets_total|kube_persistentvolumeclaim_resource_requests_storage_bytes|kube_deployment_status_observed_generation|process_resident_memory_bytes|kube_job_status_active|namespace_memory:kube_pod_container_resource_requests:sum|kubelet_running_container_count|container_network_transmit_packets_dropped_total|container_fs_reads_total|node_namespace_pod_container:container_memory_cache|kubelet_running_containers|kube_pod_info|node_namespace_pod_container:container_memory_working_set_bytes|process_cpu_seconds_total|kube_pod_container_resource_limits|node_namespace_pod_container:container_memory_swap|kube_statefulset_status_current_revision|kube_resourcequota|container_fs_writes_total|container_cpu_cfs_throttled_periods_total|storage_operation_errors_total|kubelet_pleg_relist_duration_seconds_count|kube_daemonset_status_number_available|kube_statefulset_status_replicas|kube_pod_container_status_waiting_reason|kube_pod_container_resource_requests|kubelet_cgroup_manager_duration_seconds_count|rest_client_requests_total|kubernetes_build_info|container_network_receive_packets_dropped_total|container_memory_cache|kube_namespace_status_phase|kube_node_info|kube_statefulset_status_replicas_ready|kube_deployment_status_replicas_updated|node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile|kubelet_certificate_manager_client_expiration_renew_errors|kubelet_running_pods|kube_deployment_status_replicas_available|kube_replicaset_owner|node_filesystem_size_bytes|namespace_cpu:kube_pod_container_resource_requests:sum|kube_pod_owner|kube_statefulset_status_update_revision|kubelet_server_expiration_renew_errors|kube_node_status_capacity|kubelet_pod_start_duration_seconds_count|kube_horizontalpodautoscaler_spec_min_replicas|kube_horizontalpodautoscaler_status_desired_replicas|namespace_workload_pod:kube_pod_owner:relabel|kube_statefulset_status_observed_generation|kube_daemonset_status_desired_number_scheduled|namespace_workload_pod|container_cpu_usage_seconds_total|cluster:namespace:pod_memory:active:kube_pod_container_resource_limits|kubelet_node_name|kubelet_pod_worker_duration_seconds_bucket|kubelet_volume_stats_inodes_used|kube_statefulset_status_replicas_updated|container_memory_rss|kubelet_volume_stats_available_bytes|container_memory_swap|container_memory_working_set_bytes|kube_daemonset_status_number_misscheduled|container_fs_reads_bytes_total|namespace_cpu:kube_pod_container_resource_limits:sum|kube_deployment_metadata_generation|kube_horizontalpodautoscaler_spec_max_replicas|container_network_receive_bytes_total|go_goroutines|kubelet_node_config_error|kube_node_status_condition|node_filesystem_avail_bytes|container_cpu_cfs_periods_total|kube_deployment_spec_replicas|kubelet_runtime_operations_errors_total|machine_memory_bytes|container_network_transmit_packets_total|kubelet_volume_stats_capacity_bytes|storage_operation_duration_seconds_count|kubelet_pleg_relist_interval_seconds_bucket|kubelet_runtime_operations_total|kube_node_status_allocatable|kube_daemonset_status_updated_number_scheduled|kube_pod_status_phase|kube_statefulset_replicas|kubelet_certificate_manager_client_ttl_seconds|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|container_network_transmit_bytes_total|kubelet_cgroup_manager_duration_seconds_bucket|volume_manager_total_volumes|kube_daemonset_status_current_number_scheduled|kubelet_certificate_manager_server_ttl_seconds|container_fs_writes_bytes_total|kubelet_pod_worker_duration_seconds_count|node_namespace_pod_container:container_memory_rss|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|kubelet_pleg_relist_duration_seconds_bucket|kubelet_volume_stats_inodes|kube_job_failed|kube_job_status_start_time|kube_node_spec_taint|cluster:namespace:pod_memory:active:kube_pod_container_resource_requests|kube_namespace_status_phase|container_cpu_usage_seconds_total|kube_pod_status_phase|kube_pod_start_time|kube_pod_container_status_restarts_total|kube_pod_container_info|kube_pod_container_status_waiting_reason|kube_daemonset.*|kube_replicaset.*|kube_statefulset.*|kube_job.*|kube_node.*|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|namespace_cpu:kube_pod_container_resource_requests:sum|node_cpu.*|node_memory.*|node_filesystem.*
                action: keep
            relabel_configs:
              - action: keep
                regex: kube-state-metrics
                source_labels:
                  - __meta_kubernetes_pod_label_app_kubernetes_io_name
          - job_name: integrations/node_exporter
            bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
            kubernetes_sd_configs:
              - namespaces:
                  names:
                    - ${NAMESPACE}
                role: pod
            metric_relabel_configs:
              - source_labels: [__name__]
                regex: kube_pod_status_reason|kubelet_pod_start_duration_seconds_bucket|kube_horizontalpodautoscaler_status_current_replicas|kubelet_running_pod_count|cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits|namespace_memory:kube_pod_container_resource_limits:sum|kube_statefulset_metadata_generation|container_network_receive_packets_total|kube_persistentvolumeclaim_resource_requests_storage_bytes|kube_deployment_status_observed_generation|process_resident_memory_bytes|kube_job_status_active|namespace_memory:kube_pod_container_resource_requests:sum|kubelet_running_container_count|container_network_transmit_packets_dropped_total|container_fs_reads_total|node_namespace_pod_container:container_memory_cache|kubelet_running_containers|kube_pod_info|node_namespace_pod_container:container_memory_working_set_bytes|process_cpu_seconds_total|kube_pod_container_resource_limits|node_namespace_pod_container:container_memory_swap|kube_statefulset_status_current_revision|kube_resourcequota|container_fs_writes_total|container_cpu_cfs_throttled_periods_total|storage_operation_errors_total|kubelet_pleg_relist_duration_seconds_count|kube_daemonset_status_number_available|kube_statefulset_status_replicas|kube_pod_container_status_waiting_reason|kube_pod_container_resource_requests|kubelet_cgroup_manager_duration_seconds_count|rest_client_requests_total|kubernetes_build_info|container_network_receive_packets_dropped_total|container_memory_cache|kube_namespace_status_phase|kube_node_info|kube_statefulset_status_replicas_ready|kube_deployment_status_replicas_updated|node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile|kubelet_certificate_manager_client_expiration_renew_errors|kubelet_running_pods|kube_deployment_status_replicas_available|kube_replicaset_owner|node_filesystem_size_bytes|namespace_cpu:kube_pod_container_resource_requests:sum|kube_pod_owner|kube_statefulset_status_update_revision|kubelet_server_expiration_renew_errors|kube_node_status_capacity|kubelet_pod_start_duration_seconds_count|kube_horizontalpodautoscaler_spec_min_replicas|kube_horizontalpodautoscaler_status_desired_replicas|namespace_workload_pod:kube_pod_owner:relabel|kube_statefulset_status_observed_generation|kube_daemonset_status_desired_number_scheduled|namespace_workload_pod|container_cpu_usage_seconds_total|cluster:namespace:pod_memory:active:kube_pod_container_resource_limits|kubelet_node_name|kubelet_pod_worker_duration_seconds_bucket|kubelet_volume_stats_inodes_used|kube_statefulset_status_replicas_updated|container_memory_rss|kubelet_volume_stats_available_bytes|container_memory_swap|container_memory_working_set_bytes|kube_daemonset_status_number_misscheduled|container_fs_reads_bytes_total|namespace_cpu:kube_pod_container_resource_limits:sum|kube_deployment_metadata_generation|kube_horizontalpodautoscaler_spec_max_replicas|container_network_receive_bytes_total|go_goroutines|kubelet_node_config_error|kube_node_status_condition|node_filesystem_avail_bytes|container_cpu_cfs_periods_total|kube_deployment_spec_replicas|kubelet_runtime_operations_errors_total|machine_memory_bytes|container_network_transmit_packets_total|kubelet_volume_stats_capacity_bytes|storage_operation_duration_seconds_count|kubelet_pleg_relist_interval_seconds_bucket|kubelet_runtime_operations_total|kube_node_status_allocatable|kube_daemonset_status_updated_number_scheduled|kube_pod_status_phase|kube_statefulset_replicas|kubelet_certificate_manager_client_ttl_seconds|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|container_network_transmit_bytes_total|kubelet_cgroup_manager_duration_seconds_bucket|volume_manager_total_volumes|kube_daemonset_status_current_number_scheduled|kubelet_certificate_manager_server_ttl_seconds|container_fs_writes_bytes_total|kubelet_pod_worker_duration_seconds_count|node_namespace_pod_container:container_memory_rss|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|kubelet_pleg_relist_duration_seconds_bucket|kubelet_volume_stats_inodes|kube_job_failed|kube_job_status_start_time|kube_node_spec_taint|cluster:namespace:pod_memory:active:kube_pod_container_resource_requests|kube_namespace_status_phase|container_cpu_usage_seconds_total|kube_pod_status_phase|kube_pod_start_time|kube_pod_container_status_restarts_total|kube_pod_container_info|kube_pod_container_status_waiting_reason|kube_daemonset.*|kube_replicaset.*|kube_statefulset.*|kube_job.*|kube_node.*|node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate|cluster:namespace:pod_cpu:active:kube_pod_container_resource_requests|namespace_cpu:kube_pod_container_resource_requests:sum|node_cpu.*|node_memory.*|node_filesystem.*
                action: keep
            relabel_configs:
              - action: keep
                regex: prometheus-node-exporter.*
                source_labels:
                  - __meta_kubernetes_pod_label_app_kubernetes_io_name
              - action: replace
                source_labels:
                  - __meta_kubernetes_pod_node_name
                target_label: instance
              - action: replace
                source_labels:
                  - __meta_kubernetes_namespace
                target_label: namespace
            tls_config:
              ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
              insecure_skip_verify: false
          - job_name: "kubernetes-pods"
            kubernetes_sd_configs:
              - role: pod
            relabel_configs:
              - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
                action: keep
                regex: true
              - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_metric_path]
                action: replace
                target_label: __metrics_path__
                regex: (.+)
              - action: labelmap
                regex: __meta_kubernetes_pod_label_(.+)
              - source_labels: [__meta_kubernetes_namespace]
                action: replace
                target_label: namespace
              - source_labels: [__meta_kubernetes_pod_name]
                action: replace
                target_label: pod
    integrations:
      agent:
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
            cluster: $CLUSTER_NAME
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
        image: grafana/agent:$GRAFANA_AGENT_VERSION
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

---

EOF

kubectl apply -f grafana-agent/metrics-exporter.yaml
