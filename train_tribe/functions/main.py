# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

import logging
from math import e
from firebase_functions import https_fn
from firebase_functions import scheduler_fn
from firebase_functions import firestore_fn
from firebase_admin import initialize_app
from firebase_functions.params import SecretParam
from jsonifier import jsonify
from event_options_builder import build_event_options
from event_options_save_to_db import event_options_save_to_db
from bucket_manager import download_from_bucket
import random
import os
from flask import send_file
import tempfile
import json
import datetime

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


def process_trip_options(origin, destination, event_start_time, event_end_time):
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
    return build_event_options(params), event_options_full_path, id


@firestore_fn.on_document_created(document="users/{user_id}/events/{event_id}", secrets=[GOOGLE_MAPS_API_KEY])
def firestore_event_trip_options_create(event: firestore_fn.Event[dict]) -> None:
    data = event.data.after
    if not data:
        return
    origin = data.get("origin")
    destination = data.get("destination")
    event_start_time = data.get("event_start")
    event_end_time = data.get("event_end")
    if not (origin and destination and event_start_time and event_end_time):
        return
    result, event_options_full_path, id = process_trip_options(origin, destination, event_start_time, event_end_time)
    #TODO: manage recurring events
    if result["success"]:
        params = {
            "user_id": event.params.user_id,
            "event_id": event.params.event_id,
            "event_start_time": event_start_time,
            "event_options_path": event_options_full_path,
            "bucket_name": bucket_name,
            "isRecurring": data.get("recurrent"),
            "recurrence_end_date": data.get("recurrence_end").date(),
        }
        event_options_save_to_db(params)
        if result["success"]:
            logging.info(f"Event options saved to DB for event {id}")
        else:
            logging.error(f"Error saving event options to DB: {result['message']}")
    else:
        logging.error(f"Error processing event options: {result['message']}")

@firestore_fn.on_document_deleted(document="users/{user_id}/events/{event_id}")
def firestore_event_trip_options_delete(event: firestore_fn.Event[dict]) -> None:
    data = event.data.before
    if not data:
        return
    user_id = event.params.user_id
    event_date = data.get("event_date")
    recurrence_counter = event_date.date()
    db = firestore.client()
    if data.get("recurrent"):
        recurrence_end_date = data.get("recurrence_end")
        while recurrence_counter <= recurrence_end_date:
            for route in data.get("routes", []):
                trip_ids = route.get("trip_ids")
                if trip_ids:
                    for trip_id in trip_ids:
                        # Delete the user from the trains_match collection if the user is present
                        try:
                            db.collection("trains_match").document(event_date).collection("trains").document(trip_id).collection("users").document(user_id).delete()
                        except Exception as e:
                            logging.error(f"User {user_id} is not in trip {trip_id} of date {event_date}: {e}")
            recurrence_counter += datetime.timedelta(days=7)
    else:
        for route in data.get("routes", []):
            trip_ids = route.get("trip_ids")
            if trip_ids:
                for trip_id in trip_ids:
                    # Delete the user from the trains_match collection if the user is present
                    try:
                        db.collection("trains_match").document(event_date).collection("trains").document(trip_id).collection("users").document(user_id).delete()
                    except Exception as e:
                        logging.error(f"User {user_id} is not in trip {trip_id} of date {event_date}: {e}")

@firestore_fn.on_document_updated(document="users/{user_id}/events/{event_id}", secrets=[GOOGLE_MAPS_API_KEY])
def firestore_event_trip_options_update(event: firestore_fn.Event[dict]) -> None:
    firestore_event_trip_options_delete(event)
    user_id = event.params.user_id
    event_id = event.params.event_id
    db = firestore.client()
    try:
        db.collection("users").document(user_id).collection("events").document(event_id).collection("routes").delete()
    except Exception as e:
        logging.error(f"Error deleting routes for event {event_id}: {e}")
    firestore_event_trip_options_create(event)
    

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

    result, event_options_full_path, id = process_trip_options(origin, destination, event_start_time, event_end_time)

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

