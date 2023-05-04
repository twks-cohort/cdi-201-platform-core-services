import json
import os
import sys
from xmlrpc.server import CGIXMLRPCRequestHandler

import requests

base_url = "https://team0201stack.grafana.net/api/v1/provisioning/{resource}"
headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": f'Bearer {os.getenv("STACK_MANAGEMENT_TOKEN")}'
}
contact_url = base_url.format(resource="contact-points")
notification_policy_url = base_url.format(resource="policies")

def update_contact_point(url, headers, body_json):
    contact_exists = False

    # First we have to see if the contact exists
    response = requests.get(url=url, headers=headers)
    response.raise_for_status()
    contacts= response.json()
    for contact in contacts:
        if contact["name"] == body_json["name"]:
            contact_exists = True
            break

    # If the contact exists, we have to use PUT.  Otherwise we can POST
    if contact_exists:
        url = f'{url}/{body_json["uid"]}'
        response = requests.put(url=url, headers=headers, json=body_json)
        response.raise_for_status()
    else:
        response = requests.post(url=url, headers=headers, json=body_json)
        response.raise_for_status()

def update_notification_policy(url, headers, body_json):
    response = requests.put(url=url, headers=headers, json=body_json)
    response.raise_for_status()


update_contact_point(contact_url, headers, json.load(open(os.path.join(os.fsdecode('observe/alerts/contact-point.json')))))
update_notification_policy(notification_policy_url, headers, json.load(open(os.path.join(os.fsdecode('observe/alerts/notification-policy.json')))))
