import json
import csv
import requests
import zipfile
import io
import os
import tempfile
from bucket_manager import upload_to_bucket

def jsonify(params):
    tmp_dir = tempfile.gettempdir()
    try:
        stop_times_csv = os.path.join(tmp_dir, 'stop_times.txt')
        stops_csv = os.path.join(tmp_dir, 'stops.txt')
        trips_csv = os.path.join(tmp_dir, 'trips.txt')
        stop_times_json = os.path.join(tmp_dir, 'stop-times.json')
        stops_json = os.path.join(tmp_dir, 'stops.json')
        trips_json_path = os.path.join(tmp_dir, 'trips.json')
        stops_output_path = os.path.join(tmp_dir, 'full_info_stops.json')
        trips_output_path = os.path.join(tmp_dir, 'full_info_trips.json')

        result_output_path = params["result_output_path"]
        stops_output_path = params["stops_output_path"]
        bucket_name = params["bucket_name"]

        zip_url = "https://www.dati.lombardia.it/download/3z4k-mxz9/application%2Fzip"
        response = requests.get(zip_url)
        response.raise_for_status()
    except requests.RequestException as e:
        return {"success": False, "message": f"Errore durante il download del file zip: {str(e)}"}

    try:
        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            for filename in ['stop_times.txt', 'stops.txt', 'trips.txt']:
                with z.open(filename) as src, open(os.path.join(tmp_dir, filename), 'wb') as dst:
                    dst.write(src.read())
    except (zipfile.BadZipFile, KeyError) as e:
        return {"success": False, "message": f"Errore durante l'estrazione dei file: {str(e)}"}

    try:
        with open(stop_times_csv, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            stops = list(reader)
        with open(stops_csv, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            stops_info = list(reader)
        with open(trips_csv, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            trips_info = list(reader)
    except (FileNotFoundError, csv.Error) as e:
        return {"success": False, "message": f"Errore durante la lettura dei file CSV: {str(e)}"}

    try:
        with open(stop_times_json, 'w', encoding='utf-8') as f:
            json.dump(stops, f, ensure_ascii=False, indent=2)
        with open(stops_json, 'w', encoding='utf-8') as f:
            json.dump(stops_info, f, ensure_ascii=False, indent=2)
        with open(trips_json_path, 'w', encoding='utf-8') as f:
            json.dump(trips_info, f, ensure_ascii=False, indent=2)
    except IOError as e:
        return {"success": False, "message": f"Errore durante il salvataggio dei file JSON: {str(e)}"}

    try:
        stop_id_to_name = {stop['stop_id']: stop['stop_name'] for stop in stops_info}
        for stop in stops:
            stop_id = stop.get('stop_id')
            stop['stop_name'] = stop_id_to_name.get(stop_id, None)

        with open(stops_output_path, 'w', encoding='utf-8') as f:
            json.dump(stops, f, ensure_ascii=False, indent=2)

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

    except Exception as e:
        return {"success": False, "message": f"Errore durante la creazione dei file JSON completi: {str(e)}"}

    try:
        upload_to_bucket(trips_output_path, result_output_path, bucket_name)
        upload_to_bucket(stops_json, stops_output_path, bucket_name)
    except Exception as e:
        return {"success": False, "message": f"Errore durante il caricamento su bucket: {str(e)}, temp_path: {trips_output_path}"}

    return {"success": True, "message": "Files saved successfully"}
