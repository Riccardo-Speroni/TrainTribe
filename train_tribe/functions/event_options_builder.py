from maps_asker import ask_maps
from datetime import datetime, timedelta
import tempfile
import os
import pytz
import json
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
    event_start = params["event_start_time"]
    event_end = params["event_end_time"]
    interval = timedelta(minutes=30)
    i = 0
    all_legs = []
    errors = []
    current_time = event_start
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

    # Remove duplicate routes
    unique_legs = []
    seen = set()
    for leg in all_legs:
        leg_str = json.dumps(leg, sort_keys=True)
        if leg_str not in seen:
            seen.add(leg_str)
            unique_legs.append(leg)

    # Remove routes with legs whose 'from' or 'to' stop arrival_time is outside event timeframe
    rome_tz = pytz.timezone("Europe/Rome")
    event_start_time = params["event_start_time"].astimezone(rome_tz).time()
    event_end_time = params["event_end_time"].astimezone(rome_tz).time()
    filtered_legs = []
    for route in unique_legs:
        valid = True
        for leg_key in [k for k in route.keys() if k.startswith('leg')]:
            leg = route[leg_key]
            stops = leg["stops"]
            from_id = leg["from"]
            to_id = leg["to"]
            from_stop = next((s for s in stops if s["stop_id"] == from_id), None)
            to_stop = next((s for s in stops if s["stop_id"] == to_id), None)
            if from_stop:
                arr_time_str = from_stop["arrival_time"][:5]
                arr_time = datetime.strptime(arr_time_str, "%H:%M").time()
                if arr_time < event_start_time or arr_time > event_end_time:
                    valid = False
                    break
            if to_stop:
                arr_time_str = to_stop["arrival_time"][:5]
                arr_time = datetime.strptime(arr_time_str, "%H:%M").time()
                if arr_time < event_start_time or arr_time > event_end_time:
                    valid = False
                    break
        if valid:
            filtered_legs.append(route)

    # Sort routes by departure_time of "from" station of leg0
    def get_leg0_departure(route):
        leg0 = route.get("leg0")
        if not leg0:
            return "99:99"  # Put routes without leg0 at the end
        stops = leg0.get("stops", [])
        from_id = leg0.get("from")
        from_stop = next((s for s in stops if s["stop_id"] == from_id), None)
        if from_stop:
            return from_stop.get("departure_time", "99:99")
        return "99:99"
    filtered_legs.sort(key=lambda route: get_leg0_departure(route))

    # Save merged file to a temp file and upload to bucket
    tmp_event_options_path = os.path.join(tempfile.gettempdir(), os.path.basename(params["event_options_path"]))
    with open(tmp_event_options_path, "w", encoding="utf-8") as f:
        json.dump(filtered_legs, f, ensure_ascii=False, indent=4)
    upload_to_bucket(tmp_event_options_path, params["event_options_path"], params["bucket_name"])
    success = len(errors) == 0
    return {"success": success, "message": "Event options built successfully", "errors": errors}