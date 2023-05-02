import json
import requests
import re
import sys
from kubernetes import client, config


def metrics_server_release_version():
    metrics_server_release_url = "https://api.github.com/repos/kubernetes-sigs/metrics-server/releases"
    maximum_allowed_releases_per_page = "10"
    r = requests.get(metrics_server_release_url, params={"per_page": maximum_allowed_releases_per_page})
    metrics_server_releases = json.loads(r.text)
    # filter to get metrics-server tags
    regex = re.compile("v[0-9].[0-9].[0-9]")
    latest_metrics_server_agent_version = [metrics_server_release["tag_name"] for metrics_server_release in metrics_server_releases
                                        if re.match(regex, metrics_server_release["tag_name"])]
    latest_metrics_server_version = latest_metrics_server_agent_version[0].split("-")[-1] if len(
        latest_metrics_server_agent_version) > 0 else "error"
    # latest_metrics_server_version = "d"
    return latest_metrics_server_version


def kube_state_metrics_release_version():
    kube_state_metrics_release_url = "https://api.github.com/repos/prometheus-community/helm-charts/releases"
    maximum_allowed_releases_per_page = "20"
    r = requests.get(kube_state_metrics_release_url, params={"per_page": maximum_allowed_releases_per_page})
    kube_state_metrics_releases = json.loads(r.text)

    # filter to get kube_state_metrics tags
    regex = re.compile("kube-state-metrics-[0-9].[0-9].[0-9]")
    latest_kube_state_metrics_version = [kube_state_metrics_release["tag_name"] for kube_state_metrics_release in kube_state_metrics_releases
                                        if re.match(regex, kube_state_metrics_release["tag_name"])]

    latest_kube_state_metrics_tag = latest_kube_state_metrics_version[0].split("-")[-1] if len(
        latest_kube_state_metrics_version) > 0 else "error"

    return latest_kube_state_metrics_tag

def node_exporter_release_version():
    node_exporter_release_url = "https://github.com/prometheus/node_exporter/releases/latest"
    r = requests.get(node_exporter_release_url)
    latest_node_exporter_version = r.url.split("tag/")[1].replace("v", "")
    latest_node_exporter_tag = latest_node_exporter_version.split("-")[-1] if len(
        latest_node_exporter_version) > 0 else "error"
    return latest_node_exporter_tag

#=======================================================================================================================


# print(metrics_server_release_version())
# print(kube_state_metrics_release_version())
# print(efs_csi_driver_release_version())

latest_version = f"""
{{
  "metrics_server_version": "{metrics_server_release_version()}",
  "kube_state_metrics_version": "{kube_state_metrics_release_version()}",
  "node_exporter": "{node_exporter_release_version()}"
}}
"""

print(latest_version)

# write latest versions to file
with open('latest_versions.json', 'w') as outfile:
    outfile.write(latest_version)
