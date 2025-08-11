import json
import os
import logging
from bucket_manager import upload_to_bucket, download_from_bucket
import tempfile
from difflib import SequenceMatcher
from datetime import datetime
from rapidfuzz import fuzz

def find_stop_index(trip, stop_name):
    best_match_idx = None
    best_match_ratio = 0.0
    for idx, stop in enumerate(trip['stops']):
        match_ratio = fuzz.partial_ratio(stop['stop_name'].lower(), stop_name.lower())
        if match_ratio > best_match_ratio:
            best_match_ratio = match_ratio
            best_match_idx = idx
    if best_match_ratio >= 80:  # scaled 0-100 in rapidfuzz
        return best_match_idx
    else:
        return None

def normalize_time(time_str):
    try:
        return datetime.strptime(time_str.strip().replace('\u202f', ' '), "%I:%M %p").strftime("%H:%M")
    except ValueError:
        return time_str[:5]  # fallback to existing behavior

def find_matching_trip(possible_trips, trip_short_name, departure_time, departure_stop_name):
    if len(possible_trips) == 1:
        # logging.warning(f"Only one possible trip for short name {trip_short_name}")
        return possible_trips[0]
    
    normalized_departure_time = normalize_time(departure_time)
    
    matching_trips = []

    for trip in possible_trips:
        dep_stop_idx = find_stop_index(trip, departure_stop_name)
        
        if dep_stop_idx is not None:
            trip_dep_time = trip['stops'][dep_stop_idx].get('departure_time')
            # logging.warning(f"departure stop found: index = {dep_stop_idx}, name = {departure_stop_name}.")
            
            if trip_dep_time and trip_dep_time.startswith(normalized_departure_time):
                # logging.warning(f"Found matching trip for short name {trip_short_name}: {trip['trip_id']}")
                matching_trips.append(trip)
            # else:
                # logging.warning(f"Time doesn't match! trip_dep_time: {trip_dep_time}, departure_time: {departure_time}, trip_short_name: {trip_short_name}")
    
    if len(matching_trips) == 1:
        return matching_trips[0]
    elif len(matching_trips) > 1:
        # If there are multiple matches, return the one with the highest number of stops
        matching_trips.sort(key=lambda x: len(x['stops']), reverse=True)
        return matching_trips[0]
    else:
        logging.warning(f"No matching trip found for short name {trip_short_name} with departure_time:{departure_time} from: {departure_stop_name}")
        return None

def build_full_info_maps_legs(params):
    try:
        logging.info("Starting build_full_info_maps_legs with params: %s", params)

        # Prepare file paths
        trips_path = os.path.join(tempfile.gettempdir(), "full_info_trips.json")
        maps_path = os.path.join(tempfile.gettempdir(), "maps_response.json")

        output_path = params["full_legs_path"]
        bucket_name = params["bucket_name"]
        trips_blob = params["trips_path"]
        maps_blob = params["maps_path"]

        # Download input files
        download_from_bucket(bucket_name, trips_blob, trips_path)
        download_from_bucket(bucket_name, maps_blob, maps_path)

        # Load trips and maps
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
        # Group trips by short name to handle multiple trips with same short name
        trips_by_short_name = {}
        for trip in trips:
            if 'trip_short_name' in trip:
                if trip['trip_short_name'] not in trips_by_short_name:
                    trips_by_short_name[trip['trip_short_name']] = []
                trips_by_short_name[trip['trip_short_name']].append(trip)

        logging.info("Trips grouped by short name")

        all_routes = []
        for route_idx, route in enumerate(maps['routes']):
            logging.info("Processing route %d", route_idx)
            route_result = {}
            route_has_non_trenord = False
            
            for leg_idx, leg in enumerate(route['legs']):
                logging.info("Processing leg %d", leg_idx)
                step_num = 0
                
                for step in leg['steps']:
                    # Skip non-Trenord transit steps or non-rail transit
                    if step.get('travel_mode') == 'TRANSIT':
                        agencies = step['transit_details']['line'].get('agencies', [])
                        agency_name = agencies[0]['name'] if agencies and 'name' in agencies[0] else ''
                        if 'trenord' not in agency_name.lower():
                            route_has_non_trenord = True
                            continue
                    
                    if (step.get('travel_mode') == 'TRANSIT' and 
                        step['transit_details']['line']['vehicle']['type'] == 'HEAVY_RAIL'):
                        
                        td = step['transit_details']
                        trip_short_name = td['trip_short_name']
                        
                        # Find possible trips with this short name
                        possible_trips = next((v for k, v in trips_by_short_name.items() if trip_short_name in k), [])
                        
                        # Find the exact matching trip
                        trip = find_matching_trip(
                            possible_trips, 
                            trip_short_name, 
                            td['departure_time']['text'], 
                            td['departure_stop']['name']
                        )
                        
                        if not trip:
                            logging.error(f"Trip not found for trip_short_name: {trip_short_name}")
                            continue
                        
                        # Find stop indices
                        from_idx = find_stop_index(trip, td['departure_stop']['name'])
                        to_idx = find_stop_index(trip, td['arrival_stop']['name'])
                        
                        if from_idx is None:
                            logging.error(f"Stop index not found for trip: {trip_short_name}, --from-- stop name: {td['departure_stop']['name']}")
                            continue
                        
                        if to_idx is None:
                            logging.error(f"Stop index not found for trip: {trip_short_name}, --to-- stop name: {td['arrival_stop']['name']}")
                            continue
                        
                        # Prepare stops output
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
                        
                        # Add leg to route result
                        route_result[f'leg{step_num}'] = {
                            'trip_id': trip['trip_id'],
                            'stops': stops_out,
                            'from': stops[from_idx]['stop_id'],
                            'to': stops[to_idx]['stop_id']
                        }
                        step_num += 1
            
            # Add route to all routes if it has results and is all Trenord
            if route_result and not route_has_non_trenord:
                all_routes.append(route_result)
        
        logging.info("All routes processed: %s", all_routes)

    except KeyError as e:
        logging.error("KeyError: %s", e)
        return {"success": False, "message": f"Data structure error: {str(e)}"}

    try:
        # Save output to temporary file and upload to bucket
        tmp_output_path = os.path.join(tempfile.gettempdir(), "full_info_maps_legs.json")
        with open(tmp_output_path, 'w', encoding='utf-8') as f:
            json.dump(all_routes, f, indent=2, ensure_ascii=False)

        upload_to_bucket(tmp_output_path, output_path, bucket_name)

    except IOError as e:
        logging.error("Error saving file: %s", e)
        return {"success": False, "message": f"Error saving file: {str(e)}", "full_legs": all_routes}

    return {"success": True, "message": "File saved successfully"}