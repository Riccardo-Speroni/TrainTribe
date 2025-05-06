import json
import csv
import requests
import zipfile
import io
import os
from google.cloud import storage  # Assicurati che la libreria sia installata

def upload_to_bucket(source_file, destination_blob, bucket_name):
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(destination_blob)
    blob.upload_from_filename(source_file)
    print(f"File {source_file} caricato come {destination_blob} nel bucket {bucket_name}")

def jsonify():
    # Usa la directory temporanea per Cloud Functions
    tmp_dir = '/tmp'
    stop_times_csv = os.path.join(tmp_dir, 'stop_times.txt')
    stops_csv = os.path.join(tmp_dir, 'stops.txt')
    trips_csv = os.path.join(tmp_dir, 'trips.txt')
    stop_times_json = os.path.join(tmp_dir, 'stop-times.json')
    stops_json = os.path.join(tmp_dir, 'stops.json')
    trips_json_path = os.path.join(tmp_dir, 'trips.json')
    output_path = os.path.join(tmp_dir, 'full_info_stops.json')
    trips_output_path = os.path.join(tmp_dir, 'full_info_trips.json')

    zip_url = "https://www.dati.lombardia.it/download/3z4k-mxz9/application%2Fzip"
    response = requests.get(zip_url)
    response.raise_for_status()
    with zipfile.ZipFile(io.BytesIO(response.content)) as z:
        for filename in ['stop_times.txt', 'stops.txt', 'trips.txt']:
            with z.open(filename) as src, open(os.path.join(tmp_dir, filename), 'wb') as dst:
                dst.write(src.read())

    with open(stop_times_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        stops = list(reader)
    with open(stops_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        stops_info = list(reader)
    with open(trips_csv, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        trips_info = list(reader)

    # Salva i file JSON di base
    with open(stop_times_json, 'w', encoding='utf-8') as f:
        json.dump(stops, f, ensure_ascii=False, indent=2)
    with open(stops_json, 'w', encoding='utf-8') as f:
        json.dump(stops_info, f, ensure_ascii=False, indent=2)
    with open(trips_json_path, 'w', encoding='utf-8') as f:
        json.dump(trips_info, f, ensure_ascii=False, indent=2)

    # Arricchisci stops con stop_name
    stop_id_to_name = {stop['stop_id']: stop['stop_name'] for stop in stops_info}
    for stop in stops:
        stop_id = stop.get('stop_id')
        stop['stop_name'] = stop_id_to_name.get(stop_id, None)

    # Salva full_info_stops.json
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(stops, f, ensure_ascii=False, indent=2)

    # Crea full_info_trips.json
    trips_dict = {}
    for stop in stops:
        trip_id = stop['trip_id']
        stop_info = {
            "stop_id": stop['stop_id'],
            "stop_name": stop.get('stop_name'),
            "stop_sequence": stop['stop_sequence'],
            "arrival_time": stop['arrival_time'],
            "departure_time": stop['departure_time']
        }
        trips_dict.setdefault(trip_id, []).append(stop_info)

    trip_id_to_short_name = {trip['trip_id']: trip.get('trip_short_name', None) for trip in trips_info}
    trips_json = [
        {"trip_id": trip_id, "trip_short_name": trip_id_to_short_name.get(trip_id, None), "stops": stops_list}
        for trip_id, stops_list in trips_dict.items()
    ]

    with open(trips_output_path, 'w', encoding='utf-8') as f:
        json.dump(trips_json, f, ensure_ascii=False, indent=2)

    print(f"File salvati in: {tmp_dir}")

    # Carica i file json nel bucket persistente
    bucket_name = "gs://traintribe-f2c7b.firebasestorage.app"  # Sostituisci con il nome reale del bucket
    upload_to_bucket(stop_times_json, 'maps/stop-times.json', bucket_name)
    upload_to_bucket(stops_json, 'maps/stops.json', bucket_name)
    upload_to_bucket(trips_json_path, 'maps/trips.json', bucket_name)
    upload_to_bucket(output_path, 'maps/full_info_stops.json', bucket_name)
    upload_to_bucket(trips_output_path, 'maps/full_info_trips.json', bucket_name)

# Se vuoi testare in locale:
# jsonify()
