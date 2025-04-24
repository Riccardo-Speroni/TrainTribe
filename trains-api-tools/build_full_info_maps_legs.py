import json
import os

trips_path = os.path.join('c:\\Users\\aless\\Polimi Temp\\TrainTribe\\jsons', 'full_info_trips.json')
maps_path = os.path.join('c:\\Users\\aless\\Polimi Temp\\TrainTribe\\jsons', 'maps_response.json')
output_path = os.path.join('c:\\Users\\aless\\Polimi Temp\\TrainTribe\\jsons', 'full_info_maps_legs.json')

with open(trips_path, encoding='utf-8') as f:
    trips = json.load(f)
with open(maps_path, encoding='utf-8') as f:
    maps = json.load(f)

trip_by_short = {trip['trip_short_name']: trip for trip in trips if 'trip_short_name' in trip}

def find_stop_index(trip, stop_name):
    for idx, stop in enumerate(trip['stops']):
        if stop['stop_name'] == stop_name:
            return idx
    return None

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
# Salva tutte le soluzioni in un unico file
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(all_routes, f, indent=2, ensure_ascii=False)
print(f"File unico salvato in: {output_path}")
