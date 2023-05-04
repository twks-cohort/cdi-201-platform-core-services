{
    "org_name": "seanalvarez",
    "cluster_name": "prod-us-east-2",
    "team_name": "team0-201",
    "stack_url": "https://team0201stack.grafana.net",
    "stack_management_token": "{{ op://cohorts/team0-201-svc-grafana/team0201stack_management_sa_key }}",
    "prometheus_endpoint": "{{ op://cohorts/team0-201-platform-vcluster/prometheus_endpoint }}",
    "prometheus_password": "{{ op://cohorts/team0-201-platform-vcluster/prometheus_password }}",
    "metrics_server_version": "v0.6.3",
    "prometheus_version": "v2.43.0",
    "grafana_agent_version": "v0.33.1",
    "alert_channel": "prod"
}
