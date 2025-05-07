#!/usr/bin/env python3

import tempfile
import requests
import json
import os
import time
from datetime import datetime
from bucket_manager import upload_to_bucket


endpoint = 'https://maps.googleapis.com/maps/api/directions/json?'

def ask_maps(params):

    try:
        dt = datetime.strptime(params["arrival_time"], "%Y-%m-%d %H:%M")
        new_arrival_time = int(time.mktime(dt.timetuple()))
        maps_params = {
            "mode": params["mode"],
            "transit_mode": params["transit_mode"],
            "alternatives": params["alternatives"],
            "region": params["region"],
            "origin": params["origin"],
            "destination": params["destination"],
            "arrival_time": new_arrival_time,
            "key": params["key"],
        }
    except ValueError:
        return {"success": False, "message": "Formato orario non valido. Usa YYYY-MM-DD HH:MM."}

    response = requests.get(endpoint, params=maps_params)
    if response.status_code == 200:
        tmp_output_path = os.path.join(tempfile.gettempdir(), "maps_response.json")
        with open(tmp_output_path, "w", encoding="utf-8") as f:
            json.dump(response.json(), f, ensure_ascii=False, indent=4)
            print(f"File salvato in {tmp_output_path}")
        
        # Upload the file to the bucket
        bucket_name = params["bucket_name"]
        blob_name = params["maps_path"]
        upload_to_bucket(tmp_output_path, blob_name, bucket_name)
        return {"success": True, "message": "Files saved successfully", "mops_response": response.json()}
    else:
        print(f"Error in request!: {response.status_code}")
        return {"success": False, "message": f"Error in request!: {response.status_code}"}