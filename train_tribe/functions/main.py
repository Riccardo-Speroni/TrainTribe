from math import e
import re
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
    "result_output_path": jsonified_trenord_trips_data_path,
    "stops_output_path": jsonified_trenord_stops_data_path,
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
    req_params = req.args
    if not req_params:
        logging.error("No parameters provided in request.")
        return https_fn.Response("No parameters provided.", status=400)
    else:
        # Log parameters in a readable way (avoid extra escaping in message by logging fields)
        try:
            _user = req_params.get("userId")
            _date = req_params.get("date")
            logging.info("Request parameters: date=%s, userId=%s", _date, _user)
        except Exception:
            logging.info("Request parameters present but could not be read.")

    # Accept both camelCase and snake_case for compatibility
    user_id = req_params.get("userId")
    if not user_id:
        logging.error("User ID not provided in request parameters.")
        return https_fn.Response("User ID parameter is required.", status=400)

    date = req_params.get("date")
    if not date:
        logging.error("Date not provided in request parameters.")
        return https_fn.Response("Date parameter is required.", status=400)
    logging.info("Using user_id: %s, date: %s", user_id, date)
    day_json_path = get_event_full_trip_data_logic(user_id, date, bucket_name)
    if day_json_path is not None:
        tmp_path = os.path.join(tempfile.gettempdir(), "day_event_options.json")
        download_from_bucket(bucket_name, day_json_path, tmp_path)
        with open(tmp_path, "r", encoding="utf-8") as f:
            day_options = json.load(f)
        return https_fn.Response(json.dumps(day_options), mimetype="application/json")
    else:
        return https_fn.Response("No trips found.", status=404)