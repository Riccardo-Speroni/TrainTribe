from firebase_functions import https_fn
from firebase_functions import scheduler_fn
from firebase_functions import firestore_fn
from firebase_admin import initialize_app
from firebase_functions.params import SecretParam
from jsonifier import jsonify
from event_trip_options_manager import (
    create_event_trip_options_logic, 
    delete_event_trip_options_logic, 
    update_event_trip_options_logic
)


GOOGLE_MAPS_API_KEY = SecretParam('GOOGLE_MAPS_API_KEY')

bucket_name = "traintribe-f2c7b.firebasestorage.app"
jsonified_trenord_data_path = "maps/full_info_trips.json"
full_legs_partial_path = "maps/results/full_info_legs"
maps_response_partial_path = "maps/responses/maps_response"
event_options_partial_path = "maps/events/event_options"

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

@firestore_fn.on_document_created(document="users/{user_id}/events/{event_id}", secrets=[GOOGLE_MAPS_API_KEY])
def firestore_event_trip_options_create(event: firestore_fn.Event[dict]) -> None:
    create_event_trip_options_logic(event, GOOGLE_MAPS_API_KEY)

@firestore_fn.on_document_deleted(document="users/{user_id}/events/{event_id}")
def firestore_event_trip_options_delete(event: firestore_fn.Event[dict]) -> None:
    delete_event_trip_options_logic(event)

@firestore_fn.on_document_updated(document="users/{user_id}/events/{event_id}", secrets=[GOOGLE_MAPS_API_KEY])
def firestore_event_trip_options_update(event: firestore_fn.Event[dict]) -> None:
    update_event_trip_options_logic(event, GOOGLE_MAPS_API_KEY)