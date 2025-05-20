from bucket_manager import download_from_bucket
import json
import os
import tempfile
from firebase_admin import firestore

def event_options_save_to_db(params):
    user_id = params.get("user_id")
    event_id = params.get("event_id")
    event_start_time = params.get("event_start_time")
    event_options_path = params.get("event_options_path")
    bucket_name = params.get("bucket_name")
    is_recurring = params.get("isRecurring")
    recurrence_end_date = params.get("recurrence_end_date")

    # Download the event options file from the bucket

    local_file_path = os.path.join(tempfile.gettempdir(), f"event_options_{event_id}.json")
    download_from_bucket(bucket_name, event_options_path, local_file_path)

    # Read the event options from the downloaded file
    try:
        with open(local_file_path, 'r', encoding='utf-8') as f:
            event_options = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        return {"success": False, "message": f"Error reading event options file: {str(e)}"}
    
    # Save the event options to the database
    db = firestore.client()
    # Update the event document with the event_options_path
    event_doc_ref = db.collection("users").document(user_id).collection("events").document(event_id)
    event_doc_ref.update({"event_options_path": event_options_path})
    routes_collection = event_doc_ref.collection("routes")

    # Add new routes
    for route in event_options:
        trip_ids = []
        for leg_id in route:
            trip_id = route[leg_id].get("trip_id")
            if trip_id:
                trip_ids.append(trip_id)
        # Add a new document with auto-generated ID
        routes_collection.add({"trip_ids": trip_ids})

    for route in event_options:
        trip_ids = []
        for leg_id in route:
            trip_id = route[leg_id].get("trip_id")
            from_stop = route[leg_id].get("from")
            to_stop = route[leg_id].get("to")
            if is_recurring:
                recurrence_counter = event_start_time.date()
                while(recurrence_counter <= recurrence_end_date):
                    db.collection("trains_match").document(event_start_time.date()).collection("trains").document(trip_id).collection("users").document(user_id).set({
                        "from": from_stop,
                        "to": to_stop,
                        "confirmed": False,
                    })
                    recurrence_counter += datetime.timedelta(days=7)
            else:
                db.collection("trains_match").document(event_start_time.date()).collection("trains").document(trip_id).collection("users").document(user_id).set({
                    "from": from_stop,
                    "to": to_stop,
                    "confirmed": False,
                })

    return None