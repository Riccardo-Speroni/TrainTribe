from heapq import merge
from firebase_admin import firestore
from zoneinfo import ZoneInfo
import datetime
import json
import os
import tempfile
import logging
from bucket_manager import download_from_bucket
from event_options_builder import build_event_options
from day_event_options_merger import get_day_event_trip_options_logic
from event_friends_finder import get_event_trip_friends_logic
from datetime import datetime, timezone, timedelta

jsonified_trenord_data_path = "maps/full_info_trips.json"
full_legs_partial_path = "maps/results/full_info_legs"
maps_response_partial_path = "maps/responses/maps_response"
event_options_partial_path = "maps/events/event_options"


def process_trip_options(origin, destination, event_start_time, event_end_time, event_id, key, bucket_name):
    id = event_id
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
        "key": key.value,
        "maps_path": maps_response_full_path,
        "bucket_name": bucket_name,
        "trips_path": jsonified_trenord_data_path,
        "full_legs_path": full_legs_full_path,
        "event_options_path": event_options_full_path,
    }
    return build_event_options(params), event_options_full_path

def event_options_save_to_db(params):
    user_id = params.get("user_id")
    event_id = params.get("event_id")
    event_start_date = params.get("event_start_date")
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
    event_doc_ref.set({"event_options_path": event_options_path}, merge=True)
    
    # Add new routes
    for route in event_options:
        for leg_id in route:
            trip_id = route[leg_id].get("trip_id")
            from_stop = route[leg_id].get("from")
            to_stop = route[leg_id].get("to")
            if is_recurring:
                recurrence_counter = event_start_date
                while(recurrence_counter <= recurrence_end_date):
                    date_str = recurrence_counter.strftime("%Y-%m-%d")
                    # Ensure the date document exists
                    db.collection("trains_match").document(date_str).set({"_exists": True}, merge=True)
                    db.collection("trains_match").document(date_str).collection("trains").document(trip_id).set({"lastModified": firestore.SERVER_TIMESTAMP,}, merge=True)
                    db.collection("trains_match").document(date_str).collection("trains").document(trip_id).collection("users").document(user_id).set({
                        "from": from_stop,
                        "to": to_stop,
                        "confirmed": False,
                    })
                    recurrence_counter += datetime.timedelta(days=7)
            else:
                date_str = event_start_date.strftime("%Y-%m-%d")
                # Ensure the date document exists
                db.collection("trains_match").document(date_str).set({"lastModified": firestore.SERVER_TIMESTAMP}, merge=True)
                db.collection("trains_match").document(date_str).collection("trains").document(trip_id).set({"lastModified": firestore.SERVER_TIMESTAMP,}, merge=True)
                db.collection("trains_match").document(date_str).collection("trains").document(trip_id).collection("users").document(user_id).set({
                    "from": from_stop,
                    "to": to_stop,
                    "confirmed": False,
                })

    return None

def create_event_trip_options_logic(event, key, bucket_name):
    data_raw = event.data
    if not data_raw:
        return
    # Usa .after se esiste, altrimenti usa data_raw
    if hasattr(data_raw, 'after') and data_raw.after:
        data_raw = data_raw.after
    data = data_raw.to_dict() if hasattr(data_raw, 'to_dict') else data_raw
    origin = data.get("origin")
    destination = data.get("destination")
    event_start_time = data.get("event_start")
    event_end_time = data.get("event_end")
    if not (origin and destination and event_start_time and event_end_time):
        return
    result, event_options_full_path = process_trip_options(origin, destination, event_start_time, event_end_time, f"_{event.params['user_id']}_{event.params['event_id']}", key, bucket_name)
    if result["success"]:
        params = {
            "user_id": event.params["user_id"],
            "event_id": event.params["event_id"],
            "event_start_date": event_start_time.astimezone(ZoneInfo("Europe/Rome")).date(),
            "event_options_path": event_options_full_path,
            "bucket_name": bucket_name,
            "isRecurring": data.get("recurrent"),
            # Convert recurrence_end to Europe/Rome timezone and pass as date
            "recurrence_end_date": (
                data.get("recurrence_end").astimezone(ZoneInfo("Europe/Rome")).date()
                if data.get("recurrent") and data.get("recurrence_end") else None
            ),
        }
        event_options_save_to_db(params)
        if result["success"]:
            logging.info(f"Event options saved to DB for event {event.params['event_id']}")
        else:
            logging.error(f"Error saving event options to DB: {result['message']}")
    else:
        logging.error(f"Error processing event options: {result['message']}")

def delete_event_trip_options_logic(event):
    data_raw = event.data
    if not data_raw:
        return
    # Use .before if it exists, otherwise use data_raw
    if hasattr(data_raw, 'before') and data_raw.before:
        data_raw = data_raw.before
    if hasattr(data_raw, 'to_dict'):
        data_raw = data_raw.to_dict()
    data = data_raw.to_dict() if hasattr(data_raw, 'to_dict') else data_raw
    user_id = event.params["user_id"]
    event_start_time = data.get("event_start")
    recurrence_counter = event_start_time.date()
    db = firestore.client()
    routes = data.get("routes", [])
    if not routes:
        event_id = event.params["event_id"]
        routes_docs = db.collection("users").document(user_id).collection("events").document(event_id).collection("routes").stream()
        routes = [doc.to_dict() for doc in routes_docs]
    if data.get("recurrent"):
        # Convert recurrence_end to Europe/Rome timezone and use date
        recurrence_end_date = data.get("recurrence_end").astimezone(ZoneInfo("Europe/Rome")).date()
        while recurrence_counter <= recurrence_end_date:
            for route in routes:
                trip_ids = route.get("trip_ids")
                if trip_ids:
                    for trip_id in trip_ids:
                        try:
                            db.collection("trains_match").document(recurrence_counter.strftime("%Y-%m-%d")).collection("trains").document(trip_id).collection("users").document(user_id).delete()
                        except Exception as e:
                            logging.error(f"User {user_id} is not in trip {trip_id} of date {recurrence_counter}: {e}")
            recurrence_counter += datetime.timedelta(days=7)
    else:
        for route in routes:
            trip_ids = route.get("trip_ids")
            if trip_ids:
                for trip_id in trip_ids:
                    try:
                        db.collection("trains_match").document(event_start_time.date().strftime("%Y-%m-%d")).collection("trains").document(trip_id).collection("users").document(user_id).delete()
                    except Exception as e:
                        logging.error(f"User {user_id} is not in trip {trip_id} of date {event_start_time}: {e}")

def update_event_trip_options_logic(event, key, bucket_name):

    if event.data.before is None:
        logging.error("No previous data found for event trip options update.")
        return
    else:
        logging.error("BEFORE DATA: " + event.data.before)
    if event.data.after is None:
        logging.error("No new data found for event trip options update.")
        return
    else:
        logging.error("AFTER DATA: " + event.data.after)

    before = event.data.before.to_dict()
    after = event.data.after.to_dict()

    keys = ["origin", "destination", "event_start", "event_end"]
    changed = any(before.get(k) != after.get(k) for k in keys)

    if not changed:
        logging.warning("No relevant changes detected in event trip options.")
        return
    
    delete_event_trip_options_logic(event)
    user_id = event.params["user_id"]
    event_id = event.params["event_id"]
    db = firestore.client()
    try:
        routes_ref = db.collection("users").document(user_id).collection("events").document(event_id).collection("routes")
        for doc in routes_ref.stream():
            doc.reference.delete()
    except Exception as e:
        logging.error(f"Error deleting routes for event {event_id}: {e}")
    create_event_trip_options_logic(event, key, bucket_name)

def get_event_full_trip_data_logic(user_id, date, bucket_name):

    logging.info(f"get_event_full_trip_data_logic called with user_id: {user_id}, date: {date}")

    db = firestore.client()

    # Fetch events for the user on the specified date
    events_ref = db.collection("users").document(user_id).collection("events")
    # Convert the date string to a datetime object for querying

    # Parse the input date (expected format: 'YYYY-MM-DD')
    start_dt = datetime.strptime(date, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    end_dt = start_dt + timedelta(days=1)

    query = events_ref.where("event_start", ">=", start_dt).where("event_start", "<", end_dt)
    events_docs = list(query.stream())

    logging.info(f"Found {len(events_docs)} events for user {user_id} on date {date}")
    for event in events_docs:
        logging.info(f"Event ID: {event.id}, Data: {event.to_dict()}")

    event_options_with_friends = {}

    # add friends info to event options
    for event in events_docs:
        friends_finder_params = {
            "event_options_path": event.to_dict().get("event_options_path"),
            "user_id": user_id,
            "bucket_name": bucket_name,
            "date": date
        }
        event_options_with_friends[event.id] = get_event_trip_friends_logic(friends_finder_params)

    logging.info(f"event_options_with_friends: {event_options_with_friends}")

    #merge all event options of the day into a single file
    merger_params = {
        "event_options_with_friends": event_options_with_friends,
        "bucket_name": bucket_name,
        "date": date,
        "user_id": user_id
    }

    day_events_options = get_day_event_trip_options_logic(merger_params)

    return day_events_options

    # return None