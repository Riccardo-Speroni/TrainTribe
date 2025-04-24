#!/usr/bin/env python3

import requests
import json
import os
import time
from datetime import datetime


# Esempio di endpoint: Geocoding API
endpoint = 'https://maps.googleapis.com/maps/api/directions/json?'

def get_user_inputs():
    origin = input("Inserisci la stazione di partenza: ").strip()
    destination = input("Inserisci la stazione di arrivo: ").strip()
    arrival_time_str = input("Inserisci l'orario di arrivo (formato: YYYY-MM-DD HH:MM): ").strip()
    api_key = input("Inserisci la tua API key di Google Maps: ").strip()
    if not api_key:
        print("API key non valida.")
        exit(1)
    if not origin or not destination:
        print("Stazione di partenza o arrivo non validi.")
        exit(1)
    if not arrival_time_str:
        print("Orario di arrivo non valido.")
        exit(1)
    try:
        dt = datetime.strptime(arrival_time_str, "%Y-%m-%d %H:%M")
        arrival_time = int(time.mktime(dt.timetuple()))
    except ValueError:
        print("Formato orario non valido. Usa YYYY-MM-DD HH:MM.")
        exit(1)
    return origin, destination, arrival_time, api_key

# Parametri della richiesta (esempio: indirizzo da geocodificare)
params = {
    "mode": "transit",
    "transit_mode": "train",
    "alternatives": "true",
    "region": "it",
}


origin, destination, arrival_time, apy_key = get_user_inputs()
params["origin"] = origin
params["destination"] = destination
params["arrival_time"] = arrival_time
params["key"] = apy_key


def main():
    response = requests.get(endpoint, params=params)
    if response.status_code == 200:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        output_path = os.path.join(script_dir, "maps_response.json")
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(response.json(), f, ensure_ascii=False, indent=4)
    else:
        print(f"Errore nella richiesta: {response.status_code}")

if __name__ == '__main__':
    main()