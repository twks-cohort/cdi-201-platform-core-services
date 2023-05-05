import json
import os
import sys
from xmlrpc.server import CGIXMLRPCRequestHandler

import requests

base_url = "https://team0201stack.grafana.net/api/folders"
headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": f'Bearer {os.getenv("STACK_MANAGEMENT_TOKEN")}'
}

def create_folder(url, headers, body_json):
    response = requests.post(url=url, headers=headers, json=body_json)
    response.raise_for_status()

create_folder(base_url, headers, json.load(open("observe/folders/pe-folder.json")))
