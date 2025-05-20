from bucket_manager import download_from_bucket
import json
import os
import tempfile
from firebase_admin import firestore

def event_options_save_to_db(params):
    """
    Save event options to the database.
    """

    # Extract parameters
    """
            params = {
            "user_id": context.params.user_id,
            "event_id": context.params.event_id,
            "event_options_path": event_options_full_path,
            "bucket_name": bucket_name,
        }
    """

    user_id = params.get("user_id")
    event_id = params.get("event_id")
    event_options_path = params.get("event_options_path")
    bucket_name = params.get("bucket_name")

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

    # Delete all previous routes
    previous_routes = routes_collection.stream()
    for doc in previous_routes:
        doc.reference.delete()

    # Add new routes
    for route in event_options:
        trip_ids = []
        for leg_key in route:
            trip_id = route[leg_key].get("trip_id")
            if trip_id:
                trip_ids.append(trip_id)
        # Add a new document with auto-generated ID
        routes_collection.add({"trip_ids": trip_ids})

    #TODO: Add trips and user to trains_match
    
    return None