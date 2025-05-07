# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
from firebase_functions.params import SecretParam
from jsonifier import jsonify
from maps_asker import ask_maps
from full_legs_builder import build_full_info_maps_legs
import random

GOOGLE_MAPS_API_KEY = SecretParam('GOOGLE_MAPS_API_KEY')

bucket_name = "traintribe-f2c7b.firebasestorage.app"
jsonified_trenord_data_path = "maps/full_info_trips.json"
full_legs_partial_path = "maps/results/full_info_legs"
maps_response_partial_path = "maps/maps_response"

initialize_app()

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

@https_fn.on_request()
def get_trip_options(req: https_fn.Request) -> https_fn.Response:
    # Get parameters from the request
    origin = req.args.get("origin")
    destination = req.args.get("destination")
    arrival_time_str = req.args.get("arrival_time")

    if not GOOGLE_MAPS_API_KEY.value:
        return https_fn.Response("API key is required", status=400)
    if not origin or not destination:
        return https_fn.Response("Origin or destination is required", status=400)
    if not arrival_time_str:
        return https_fn.Response("Arrival time is required", status=400)

    randomvalue = random.randint(1000000, 9999999)
    maps_response_full_path = maps_response_partial_path + randomvalue + ".json"

    params = {
        "mode": "transit",
        "transit_mode": "train",
        "alternatives": "true",
        "region": "it",
        "origin": origin,
        "destination": destination,
        "arrival_time": arrival_time_str,
        "key": GOOGLE_MAPS_API_KEY.value,
        "maps_path": maps_response_full_path,
        "bucket_name": bucket_name,
    }

    result = ask_maps(params)

    if result["success"]:

        params = {
            "trips_path": jsonified_trenord_data_path,
            "maps_path": maps_response_full_path,
            "bucket_name": bucket_name,
            "result_output_path": full_legs_partial_path + randomvalue + ".json",
        }

        result = build_full_info_maps_legs(params)
        if result["success"]:

            return https_fn.Response(f"Full legs data has been saved successfully")
        else:
            return https_fn.Response(f"Error: {result['message']}", status=500)
    else:
        return https_fn.Response(f"Error: {result['message']}", status=500)

