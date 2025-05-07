import json
import os
from bucket_manager import upload_to_bucket, download_from_bucket
import tempfile

def find_stop_index(trip, stop_name):
    for idx, stop in enumerate(trip['stops']):
        if stop['stop_name'] == stop_name:
            return idx
    return None

def build_full_info_maps_legs(params):
    try:

        trips_path = os.path.join(tempfile.gettempdir(), "full_info_trips.json")
        maps_path = os.path.join(tempfile.gettempdir(), "maps_response.json")

        output_path = params["result_output_path"]
        bucket_name = params["bucket_name"]
        trips_blob = params["trips_path"]
        maps_blob = params["maps_path"]

        download_from_bucket(bucket_name, trips_blob, trips_path)
        download_from_bucket(bucket_name, maps_blob, maps_path)

        with open(trips_path, encoding='utf-8') as f:
            trips = json.load(f)
        with open(maps_path, encoding='utf-8') as f:
            maps = json.load(f)
    except FileNotFoundError as e:
        return {"success": False, "message": f"File not found: {str(e)}"}
    except json.JSONDecodeError as e:
        return {"success": False, "message": f"JSON parsing error: {str(e)}"}

    try:
        trip_by_short = {trip['trip_short_name']: trip for trip in trips if 'trip_short_name' in trip}

        all_routes = []
        for route_idx, route in enumerate(maps['routes']):
            route_result = {}
            for leg_idx, leg in enumerate(route['legs']):
                step_num = 0
                for step in leg['steps']:
                    if step.get('travel_mode') == 'TRANSIT' and step['transit_details']['line']['vehicle']['type'] == 'HEAVY_RAIL':
                        td = step['transit_details']
                        trip_short_name = td['trip_short_name']
                        trip = trip_by_short.get(trip_short_name)
                        if not trip:
                            continue
                        from_idx = find_stop_index(trip, td['departure_stop']['name'])
                        to_idx = find_stop_index(trip, td['arrival_stop']['name'])
                        if from_idx is None or to_idx is None:
                            continue
                        stops = trip['stops']
                        stops_out = []
                        for s in stops:
                            stops_out.append({
                                'stop_id': s['stop_id'],
                                'stop_name': s['stop_name'],
                                'stop_sequence': s['stop_sequence'],
                                'arrival_time': s.get('arrival_time'),
                                'departure_time': s.get('departure_time')
                            })
                        route_result[f'leg{step_num}'] = {
                            'trip_id': trip['trip_id'],
                            'stops': stops_out,
                            'from': stops[from_idx]['stop_id'],
                            'to': stops[to_idx]['stop_id']
                        }
                        step_num += 1
            if route_result:
                all_routes.append(route_result)
    except KeyError as e:
        return {"success": False, "message": f"Data structure error: {str(e)}"}

    try:
        tmp_output_path = os.path.join(tempfile.gettempdir(), "full_info_maps_legs.json")
        with open(tmp_output_path, 'w', encoding='utf-8') as f:
            json.dump(all_routes, f, indent=2, ensure_ascii=False)

        upload_to_bucket(tmp_output_path, output_path, bucket_name)

    except IOError as e:
        return {"success": False, "message": f"Error saving file: {str(e)}", "full_legs": all_routes}

    return {"success": True, "message": "File saved successfully", "path": output_path}
