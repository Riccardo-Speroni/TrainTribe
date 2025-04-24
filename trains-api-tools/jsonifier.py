import json
import os
import csv
import requests
import zipfile
import io

def main():
    zip_url = "https://www.dati.lombardia.it/download/3z4k-mxz9/application%2Fzip"
    response = requests.get(zip_url)
    response.raise_for_status()
    with zipfile.ZipFile(io.BytesIO(response.content)) as z:
        for filename in ['stop_times.txt', 'stops.txt', 'trips.txt']:
            with z.open(filename) as src, open(os.path.join(os.path.dirname(__file__), filename), 'wb') as dst:
                dst.write(src.read())
    stop_times_csv = os.path.join(os.path.dirname(__file__), 'stop_times.txt')
    stops_csv = os.path.join(os.path.dirname(__file__), 'stops.txt')
    trips_csv = os.path.join(os.path.dirname(__file__), 'trips.txt')
    with open(stop_times_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        stops = list(reader)
    with open(stops_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        stops_info = list(reader)
    with open(trips_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        trips_info = list(reader)
    stop_times_json = os.path.join(os.path.dirname(__file__), 'stop-times.json')
    stops_json = os.path.join(os.path.dirname(__file__), 'stops.json')
    trips_json_path = os.path.join(os.path.dirname(__file__), 'trips.json')
    with open(stop_times_json, 'w', encoding='utf-8') as f:
        json.dump(stops, f, ensure_ascii=False, indent=2)
    with open(stops_json, 'w', encoding='utf-8') as f:
        json.dump(stops_info, f, ensure_ascii=False, indent=2)
    with open(trips_json_path, 'w', encoding='utf-8') as f:
        json.dump(trips_info, f, ensure_ascii=False, indent=2)
    stop_id_to_name = {stop['stop_id']: stop['stop_name'] for stop in stops_info}
    for stop in stops:
        stop_id = stop.get('stop_id')
        stop['stop_name'] = stop_id_to_name.get(stop_id, None)
    output_path = os.path.join(os.path.dirname(stop_times_json), 'full_info_stops.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(stops, f, ensure_ascii=False, indent=2)

        trips = {}
        for stop in stops:
            trip_id = stop['trip_id']
            stop_info = {
                "stop_id": stop['stop_id'],
                "stop_name": stop.get('stop_name'),
                "stop_sequence": stop['stop_sequence'],
                "arrival_time": stop['arrival_time'],
                "departure_time": stop['departure_time']
            }
            trips.setdefault(trip_id, []).append(stop_info)

        # Costruisco una mappa trip_id -> trip_short_name
        trip_id_to_short_name = {trip['trip_id']: trip.get('trip_short_name', None) for trip in trips_info}

        trips_json = [
            {"trip_id": trip_id, "trip_short_name": trip_id_to_short_name.get(trip_id, None), "stops": stops_list}
            for trip_id, stops_list in trips.items()
        ]

        trips_output_path = os.path.join(os.path.dirname(stop_times_json), 'full_info_trips.json')
        with open(trips_output_path, 'w', encoding='utf-8') as f:
            json.dump(trips_json, f, ensure_ascii=False, indent=2)
    
    print(f"File salvato in: {output_path}")

if __name__ == '__main__':
    main()
