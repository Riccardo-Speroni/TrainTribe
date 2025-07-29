from firebase_functions import https_fn
from firebase_functions import firestore_fn
from firebase_admin import initialize_app
from firebase_functions.params import SecretParam
from firebase_functions import scheduler_fn
import json
import tempfile
import os
import logging
from jsonifier import jsonify
from bucket_manager import download_from_bucket
from event_trip_options_manager import (
    create_event_trip_options_logic, 
    delete_event_trip_options_logic, 
    update_event_trip_options_logic,
    get_event_full_trip_data_logic,
)
GOOGLE_MAPS_API_KEY = SecretParam('GOOGLE_MAPS_API_KEY')

bucket_name = "traintribe-f2c7b.firebasestorage.app"
jsonified_trenord_trips_data_path = "maps/full_info_trips.json"
jsonified_trenord_stops_data_path = "maps/stops.json"
full_legs_partial_path = "maps/results/full_info_legs"
maps_response_partial_path = "maps/responses/maps_response"
event_options_partial_path = "maps/events/event_options"

initialize_app()

@https_fn.on_request()
def call_jsonify(req: https_fn.Request) -> https_fn.Response:
    
    params = {
        "result_output_path": jsonified_trenord_trips_data_path,
        "stops_output_path": jsonified_trenord_stops_data_path,
        "bucket_name": bucket_name,
    }

    result = jsonify(params)

    if result["success"]:
        return https_fn.Response(result["message"])
    else:
        return https_fn.Response(f"Error: {result['message']}", status=500)
    
@scheduler_fn.on_schedule(schedule="0 0 * * 1")
def call_jsonify_scheduled(req: https_fn.Request) -> https_fn.Response:
    params = {
        "result_output_path": jsonified_trenord_data_path,
        "bucket_name": bucket_name,
    }

    result = jsonify(params)

    if result["success"]:
        return https_fn.Response(result["message"])
    else:
        return https_fn.Response(f"Error: {result['message']}", status=500)

@firestore_fn.on_document_created(document="users/{user_id}/events/{event_id}", secrets=[GOOGLE_MAPS_API_KEY])
def firestore_event_trip_options_create(event: firestore_fn.Event[dict]) -> None:
    create_event_trip_options_logic(event, GOOGLE_MAPS_API_KEY, bucket_name)

@firestore_fn.on_document_deleted(document="users/{user_id}/events/{event_id}")
def firestore_event_trip_options_delete(event: firestore_fn.Event[dict]) -> None:
    delete_event_trip_options_logic(event)

@firestore_fn.on_document_updated(document="users/{user_id}/events/{event_id}", secrets=[GOOGLE_MAPS_API_KEY])
def firestore_event_trip_options_update(event: firestore_fn.Event[dict]) -> None:
    update_event_trip_options_logic(event, GOOGLE_MAPS_API_KEY, bucket_name)

@https_fn.on_request()
def get_event_full_trip_data(req: https_fn.Request) -> https_fn.Response:
    #TODO: Use user_id and date from request parameters
    user_id = "pwgIShdGUgRhsyi0ss5wtRWaKQ7P"
    date = "2025-05-29"
    day_json_path = get_event_full_trip_data_logic(user_id, date, bucket_name)
    if day_json_path is not None:
        tmp_path = os.path.join(tempfile.gettempdir(), "day_event_options.json")
        download_from_bucket(bucket_name, day_json_path, tmp_path)
        with open(tmp_path, "r", encoding="utf-8") as f:
            day_options = json.load(f)
        return https_fn.Response(json.dumps(day_options), mimetype="application/json")

    else:
        return https_fn.Response("No trips found or an error occurred.", status=500)

# @https_fn.on_request()
# def get_event_trip_friends(req: https_fn.Request) -> https_fn.Response:
#     params = {
#         "event_options_path": req.args.get("event_options_path"),
#         "user_id": req.args.get("user_id"),
#         "bucket_name": bucket_name,
#         "date": req.args.get("date"),
#     }
    
#     result = get_event_trip_friends_logic(params)

#     if result is not None:
#         return https_fn.Response(result)
#     else:
#         return https_fn.Response("No friends found or an error occurred.", status=500)