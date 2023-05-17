{
    "org_name": "myOrg",
    "cluster_name": "prod-us-east-2",
    "team_name": "team##",
    "stack_url": "https://team##201stack.grafana.net",
    "stack_management_token": "{{ op://cohorts/team##-201-svc-grafana/team##201stack_management_sa_key }}",
    "prometheus_endpoint": "{{ op://cohorts/team##-201-platform-vcluster/prometheus_endpoint }}",
    "prometheus_password": "{{ op://cohorts/team##-201-platform-vcluster/prometheus_password }}",
    "node_exporter_port": "9100 + Team#",
    "metrics_server_version": "v0.6.3",
    "prometheus_version": "v2.42.0",
    "grafana_agent_version": "v0.33.1",
    "alert_channel": "prod"
}
