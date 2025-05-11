from maps_asker import ask_maps
from datetime import datetime, timedelta
from bucket_manager import download_from_bucket, upload_to_bucket

"""
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
"""

def build_event_options(params):
    event_start = datetime.strptime(params["event_start_time"], "%Y-%m-%d %H:%M")
    event_end = datetime.strptime(params["event_end_time"], "%Y-%m-%d %H:%M")
    interval = timedelta(minutes=30)
    i = 0
    all_legs = []
    errors = []
    current_time = event_start
    import tempfile, json, os
    while current_time <= event_end:
        arrival_time_str = current_time.strftime("%Y-%m-%d %H:%M")
        maps_asker_params = {
            "mode": params["mode"],
            "transit_mode": params["transit_mode"],
            "alternatives": params["alternatives"],
            "region": params["region"],
            "origin": params["origin"],
            "destination": params["destination"],
            "arrival_time": arrival_time_str,
            "key": params["key"],
            "maps_path": f"{params['maps_path']}_{i}.json",
            "trips_path": params["trips_path"],
            "full_legs_path": f"{params['full_legs_path']}_{i}.json",
            "bucket_name": params["bucket_name"],
        }
        result = ask_maps(maps_asker_params)
        if not result.get("success"):
            errors.append({"interval": i, "error": result.get("message", "Unknown error")})
        else:
            try:
                blob_name = f"{params['full_legs_path']}_{i}.json"
                tmp_path = os.path.join(tempfile.gettempdir(), f"full_legs_{i}.json")
                download_from_bucket(params["bucket_name"], blob_name, tmp_path)
                with open(tmp_path, "r", encoding="utf-8") as f:
                    legs = json.load(f)
                    all_legs.extend(legs)
            except Exception as e:
                errors.append({"interval": i, "error": str(e)})
        current_time += interval
        i += 1
    # Remove duplicate routes (all trip_id for all legs are the same)
    unique_routes = []
    seen = set()
    for route in all_legs:
        trip_ids = tuple(leg.get("trip_id") for leg in route.get("legs", []))
        if trip_ids not in seen:
            seen.add(trip_ids)
            unique_routes.append(route)
    # Remove trips where 'from' is a station transited before event_start_time
    filtered_routes = []
    for route in unique_routes:
        keep = True
        for leg in route.get("legs", []):
            if "from_time" in leg and leg["from_time"] < params["event_start_time"]:
                keep = False
                break
        if keep:
            filtered_routes.append(route)
    # Save merged file to a temp file and upload to bucket
    import tempfile
    tmp_event_options_path = os.path.join(tempfile.gettempdir(), os.path.basename(params["event_options_path"]))
    with open(tmp_event_options_path, "w", encoding="utf-8") as f:
        json.dump(filtered_routes, f, ensure_ascii=False, indent=2)
    upload_to_bucket(tmp_event_options_path, params["event_options_path"], params["bucket_name"])
    success = len(errors) == 0
    return {"success": success, "message": "Event options built successfully", "errors": errors}