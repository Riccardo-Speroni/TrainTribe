import json
from bucket_manager import download_from_bucket, upload_to_bucket
import tempfile
import os

def get_day_event_trip_options_logic(params):

    event_options_with_friends = params.get("event_options_with_friends")
    user_id = params.get("user_id")
    bucket_name = params.get("bucket_name")
    date = params.get("date")


    # This function merges all event options of the day into a single list (not dict)
    if not event_options_with_friends:
        print("No event options to merge.")
        return None

    merged_routes = {}
    for event_id, json_path in event_options_with_friends.items():
        tmp_path = os.path.join(tempfile.gettempdir(), os.path.basename(json_path))
        download_from_bucket(bucket_name, json_path, tmp_path)
        with open(tmp_path, "r", encoding="utf-8") as f:
            day_options = json.load(f)
            merged_routes[event_id] = day_options

    merged_filename = f"merged_day_event_options_{user_id}.json"
    merged_tmp_path = os.path.join(tempfile.gettempdir(), merged_filename)
    with open(merged_tmp_path, "w", encoding="utf-8") as f:
        json.dump(merged_routes, f, ensure_ascii=False, indent=4)

    # Upload merged file to bucket
    merged_bucket_path = f"maps/day_events/{date}/{merged_filename}"
    upload_to_bucket(merged_tmp_path, merged_bucket_path, bucket_name)
    return merged_bucket_path