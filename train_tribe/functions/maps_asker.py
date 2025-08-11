#!/usr/bin/env python3

import logging
import tempfile
import requests
import json
import os
from datetime import datetime
from zoneinfo import ZoneInfo
from bucket_manager import upload_to_bucket
from full_legs_builder import build_full_info_maps_legs

#TODO: create a request every 15 minutes from the start of the event up to the end of the event, save each response to params["maps_path"] + "_" + str(i) + ".json"

endpoint = 'https://maps.googleapis.com/maps/api/directions/json?'

def ask_maps(params):

    try:
        dt = datetime.strptime(params["arrival_time"], "%Y-%m-%d %H:%M")
        dt_utc = dt.replace(tzinfo=ZoneInfo("UTC"))
        new_arrival_time = int(dt_utc.timestamp())
        maps_params = {
            "mode": params["mode"],
            "transit_mode": params["transit_mode"],
            "alternatives": params["alternatives"],
            "region": params["region"],
            "origin": params["origin"],
            "destination": params["destination"],
            "arrival_time": new_arrival_time,
            "key": params["key"],
            "language": "it",
            "region": "it",
        }
    except ValueError:
        return {"success": False, "message": "Formato orario non valido. Usa YYYY-MM-DD HH:MM."}

    
    response = requests.get(endpoint, params=maps_params)
    if response.status_code == 200:
        response_json = response.json()        
        try:
            tmp_output_path = os.path.join(tempfile.gettempdir(), "maps_response.json")
            with open(tmp_output_path, 'w', encoding='utf-8') as f:
                json.dump(response_json, f, indent=2, ensure_ascii=False)

            upload_to_bucket(tmp_output_path, params["maps_path"], params["bucket_name"])

        except IOError as e:
            logging.error("Error saving file: %s", e)
            return {"success": False, "message": f"Error saving file: {e}"}

        #prepare params for full_legs_builder function

        full_legs_params={
            "full_legs_path": params["full_legs_path"],
            "bucket_name": params["bucket_name"],
            "trips_path": params["trips_path"],
            "maps_path": params["maps_path"],
        }

        #call full_legs_builder function

        result = build_full_info_maps_legs(full_legs_params)

        if result["success"]:
            return {"success": True, "message": "Full legs builder completed successfully."}
        else:
            logging.error("Full legs builder error: %s", result["message"])
            return {"success": False, "message": f"Full legs builder error: {result['message']}"}
        
    else:
        logging.error("Error in Google Maps API request: %s", response.text)
        return {"success": False, "message": f"Error in Google Maps API request: {response.text}"}