import json
import os
import logging
from bucket_manager import upload_to_bucket, download_from_bucket
import tempfile
from difflib import SequenceMatcher

def find_stop_index(trip, stop_name):
    best_match_idx = None
    best_match_ratio = 0.0
    for idx, stop in enumerate(trip['stops']):
        match_ratio = SequenceMatcher(None, stop['stop_name'].lower(), stop_name.lower()).ratio()
        if match_ratio > best_match_ratio:
            best_match_ratio = match_ratio
            best_match_idx = idx
    # Consider a match valid only if the ratio is above a threshold (e.g., 0.8)
    return best_match_idx if best_match_ratio >= 0.8 else None

def build_full_info_maps_legs(params):
    try:
        logging.info("Starting build_full_info_maps_legs with params: %s", params)

        trips_path = os.path.join(tempfile.gettempdir(), "full_info_trips.json")
        maps_path = os.path.join(tempfile.gettempdir(), "maps_response.json")

        output_path = params["full_legs_path"]
        bucket_name = params["bucket_name"]
        trips_blob = params["trips_path"]
        maps_blob = params["maps_path"]

        download_from_bucket(bucket_name, trips_blob, trips_path)
        download_from_bucket(bucket_name, maps_blob, maps_path)

        with open(trips_path, encoding='utf-8') as f:
            trips = json.load(f)
        with open(maps_path, encoding='utf-8') as f:
            maps = json.load(f)

        logging.info("Trips loaded: %s", trips)
        logging.info("Maps loaded: %s", maps)

    except FileNotFoundError as e:
        logging.error("File not found: %s", e)
        return {"success": False, "message": f"File not found: {str(e)}"}
    except json.JSONDecodeError as e:
        logging.error("JSON parsing error: %s", e)
        return {"success": False, "message": f"JSON parsing error: {str(e)}"}

    try:
        trip_by_short = {
            trip['trip_short_name']: trip for trip in trips if 'trip_short_name' in trip
        }
        logging.info("Trip by short name mapping created.")

        all_routes = []
        for route_idx, route in enumerate(maps['routes']):
            logging.info("Processing route %d", route_idx)
            route_result = {}
            route_has_non_trenord = False
            for leg_idx, leg in enumerate(route['legs']):
                logging.info("Processing leg %d", leg_idx)
                step_num = 0
                for step in leg['steps']:
                    if step.get('travel_mode') == 'TRANSIT':
                        agencies = step['transit_details']['line'].get('agencies', [])
                        agency_name = agencies[0]['name'] if agencies and 'name' in agencies[0] else ''
                        if 'trenord' not in agency_name.lower():
                            route_has_non_trenord = True
                            continue
                    if step.get('travel_mode') == 'TRANSIT' and step['transit_details']['line']['vehicle']['type'] == 'HEAVY_RAIL':
                        td = step['transit_details']
                        trip_short_name = td['trip_short_name']
                        trip = trip_by_short.get(trip_short_name)
                        if not trip:
                            logging.error("Trip not found for trip_short_name: %s", trip_short_name)
                            continue
                        from_idx = find_stop_index(trip, td['departure_stop']['name'])
                        to_idx = find_stop_index(trip, td['arrival_stop']['name'])
                        if from_idx is None:
                            logging.error("Stop index not found for trip: %s, --from-- stop name: %s", trip_short_name, td['departure_stop']['name'])
                            continue
                        if to_idx is None:
                            logging.error("Stop index not found for trip: %s, --to-- stop name: %s", trip_short_name, td['arrival_stop']['name'])
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
            if route_result and not route_has_non_trenord:
                all_routes.append(route_result)
        logging.info("All routes processed: %s", all_routes)

    except KeyError as e:
        logging.error("KeyError: %s", e)
        return {"success": False, "message": f"Data structure error: {str(e)}"}

    try:
        tmp_output_path = os.path.join(tempfile.gettempdir(), "full_info_maps_legs.json")
        with open(tmp_output_path, 'w', encoding='utf-8') as f:
            json.dump(all_routes, f, indent=2, ensure_ascii=False)

        upload_to_bucket(tmp_output_path, output_path, bucket_name)

    except IOError as e:
        logging.error("Error saving file: %s", e)
        return {"success": False, "message": f"Error saving file: {str(e)}", "full_legs": all_routes}

    return {"success": True, "message": "File saved successfully"}
