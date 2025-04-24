#!/usr/bin/env python3

import requests
import json
import os

# Sostituisci con la tua API key di Google Maps
API_KEY = 'AIzaSyAfKJSrrRqlMH63KucLkKf6huh2JMfujZU'
# Esempio di endpoint: Geocoding API
endpoint = 'https://maps.googleapis.com/maps/api/directions/json?'

# Parametri della richiesta (esempio: indirizzo da geocodificare)
params = {
    "origin": "Bergamo FS",
    "destination": "busto arsizio FS",
    "mode": "transit",
    "transit_mode": "train",
    "arrival_time": 1744912744,
    "alternatives": "true",
    "region": "it",
    "key": API_KEY,
}

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