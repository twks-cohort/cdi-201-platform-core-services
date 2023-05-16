import json
import os
import sys
from xmlrpc.server import CGIXMLRPCRequestHandler

import requests

base_url = "https://team##201stack.grafana.net/api/folders"
headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    "Authorization": f'Bearer {os.getenv("STACK_MANAGEMENT_TOKEN")}'
}

def upsert_folder(url, headers, body_json):
    folder_exists = False
    # First we have to see if the folder exists
    response = requests.get(url=url, headers=headers)
    response.raise_for_status()
    folders = response.json()
    for folder in folders:
        if folder["title"] == body_json["title"]:
            folder_exists = True
            break
    # If the folder exists, we have to use PUT.  Otherwise we can POST
    if folder_exists:
        url = f'{url}/{body_json["uid"]}'
        response = requests.put(url=url, headers=headers, json=body_json)
        response.raise_for_status()
    else:
        response = requests.post(url=url, headers=headers, json=body_json)
        response.raise_for_status()

#folders
directory = os.fsencode("observe/folders")
for file in os.listdir(directory):
    filename = os.fsdecode(file)
    if filename.endswith(".json"):
        upsert_folder(base_url, headers, json.load(open(os.path.join(os.fsdecode(directory), filename))))

print("Folders deployed successfully")
