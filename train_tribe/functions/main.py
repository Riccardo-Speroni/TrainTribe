# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_functions import scheduler_fn
from firebase_admin import initialize_app
from firebase_functions.params import SecretParam
from jsonifier import jsonify
from event_options_builder import build_event_options
from bucket_manager import download_from_bucket
import random
import os
from flask import send_file
import tempfile
import json

GOOGLE_MAPS_API_KEY = SecretParam('GOOGLE_MAPS_API_KEY')

bucket_name = "traintribe-f2c7b.firebasestorage.app"
jsonified_trenord_data_path = "maps/full_info_trips.json"
full_legs_partial_path = "maps/results/full_info_legs"
maps_response_partial_path = "maps/responses/maps_response"
event_options_partial_path = "maps/events/event_options"

initialize_app()


#Not working because of some role permissions issue. 
#Check:

# Failed to set the IAM Policy on the Service projects/traintribe-f2c7b/locations/us-central1/services/scheduled-call-jsonify

# Functions deploy had errors with the following functions:
#         scheduled_call_jsonify(us-central1)

# Unable to set the invoker for the IAM policy on the following functions:
#         scheduled_call_jsonify(us-central1)

# Some common causes of this:

# - You may not have the roles/functions.admin IAM role. Note that roles/functions.developer does not allow you to change IAM policies.

# - An organization policy that restricts Network Access on your project.
# Function URL (call_jsonify(us-central1)): https://call-jsonify-v75np53hva-uc.a.run.app
# Function URL (get_trip_options(us-central1)): https://get-trip-options-v75np53hva-uc.a.run.app

# Error: There was an error deploying functions

# @scheduler_fn.on_schedule(schedule="0 0 * * 1", timezone="Europe/Rome")
# def scheduled_call_jsonify(event):
#     params = {
#         "result_output_path": jsonified_trenord_data_path,
#         "bucket_name": bucket_name,
#     }
#     result = jsonify(params)
#     if result["success"]:
#         return "Scheduled jsonify completed successfully"
#     else:
#         return f"Scheduled jsonify error: {result['message']}"


@https_fn.on_request()
def call_jsonify(req: https_fn.Request) -> https_fn.Response:
    
    params = {
        "result_output_path": jsonified_trenord_data_path,
        "bucket_name": bucket_name,
    }

    result = jsonify(params)

    if result["success"]:
        return https_fn.Response(result["message"])
    else:
        return https_fn.Response(f"Error: {result['message']}", status=500)


@https_fn.on_request(secrets=[GOOGLE_MAPS_API_KEY])
def get_trip_options(req: https_fn.Request) -> https_fn.Response:
    # Get parameters from the request
    origin = req.args.get("origin")
    destination = req.args.get("destination")
    event_start_time = req.args.get("event_start_time")
    event_end_time = req.args.get("event_end_time")

    if not GOOGLE_MAPS_API_KEY.value:
        return https_fn.Response("API key is required", status=400)
    if not origin or not destination:
        return https_fn.Response("Origin or destination is required", status=400)
    if not event_start_time:
        return https_fn.Response("Event start time is required", status=400)
    if not event_end_time:
        return https_fn.Response("Arrival time is required", status=400)

    id = random.randint(1000000, 9999999)
    maps_response_full_path = maps_response_partial_path + str(id) + ".json"
    full_legs_full_path = full_legs_partial_path + str(id) + ".json"
    event_options_full_path = event_options_partial_path + str(id) + ".json"

    params = {
        "mode": "transit",
        "transit_mode": "train",
        "alternatives": "true",
        "region": "it",
        "origin": origin,
        "destination": destination,
        "event_end_time": event_end_time,
        "event_start_time": event_start_time,
        "key": GOOGLE_MAPS_API_KEY.value,
        "maps_path": maps_response_full_path,
        "bucket_name": bucket_name,
        "trips_path": jsonified_trenord_data_path,
        "full_legs_path": full_legs_full_path,
        "event_options_path": event_options_full_path,
    }

    result = build_event_options(params)

    if result["success"]:
        # Download the result file from the bucket
        local_file_path = os.path.join(tempfile.gettempdir(), f"full_info_legs_{id}.json")
        download_from_bucket(bucket_name, event_options_full_path, local_file_path)
        # Send the file as an attachment
        return send_file(
            local_file_path,
            as_attachment=True,
            download_name=f"event_options_{id}.json",
            mimetype="application/json"
        )
    else:
        return https_fn.Response(f"Error: {result['message']}", status=500)

