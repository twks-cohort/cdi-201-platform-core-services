import json
import os
import sys
from xmlrpc.server import CGIXMLRPCRequestHandler

import requests

base_url = "https://team##201stack.grafana.net/api/v1/provisioning/{resource}"
headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": f'Bearer {os.getenv("STACK_MANAGEMENT_TOKEN")}'
}
alert_headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": f'Bearer {os.getenv("STACK_MANAGEMENT_TOKEN")}',
    "X-Disable-Provenance": "disabled"
}
contact_url = base_url.format(resource="contact-points")
notification_policy_url = base_url.format(resource="policies")
alert_url=base_url.format(resource="alert-rules")

def upsert_record(url, headers, body_json):
    record_exists = False

    # First we have to see if the contact exists
    response = requests.get(url=url, headers=headers)
    response.raise_for_status()
    records= response.json()
    for record in records:
        if "name" in record:
            if record["name"] == body_json["name"]:
                record_exists = True
                break
        else:
            if "title" in record:
                if record["title"] == body_json["title"]:
                    record_exists = True
                    break

    # If the record exists, we have to use PUT.  Otherwise we can POST
    if record_exists:
        url = f'{url}/{body_json["uid"]}'
        response = requests.put(url=url, headers=headers, json=body_json)
        response.raise_for_status()
    else:
        response = requests.post(url=url, headers=headers, json=body_json)
        response.raise_for_status()

def post_record(url, headers, body_json):
    response = requests.put(url=url, headers=headers, json=body_json)
    response.raise_for_status()

#contacts
upsert_record(contact_url, headers, json.load(open(os.path.join(os.fsdecode('observe/alert-policy/contact-point.json')))))
#notification_policies
post_record(notification_policy_url, headers, json.load(open(os.path.join(os.fsdecode('observe/alert-policy/notification-policy.json')))))
#alerts
directory = os.fsencode("observe/alerts")
for file in os.listdir(directory):
    filename = os.fsdecode(file)
    if filename.endswith(".json"):
        upsert_record(alert_url, alert_headers, json.load(open(os.path.join(os.fsdecode(directory), filename))))

print("Alerts deployed successfully")
