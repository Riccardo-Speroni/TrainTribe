import json
import requests
import os

# Cloud Function URL
# url = "https://get-trip-options-v75np53hva-uc.a.run.app"

# Emulator URL
url = "http://127.0.0.1:5001/traintribe-f2c7b/us-central1/get_trip_options"

params = {
    "origin": "Ponte San Pietro",
    "destination": "Treviglio Ovest",
    "event_start_time": "2025-05-13 06:00",
    "event_end_time": "2025-05-13 09:00",
}

response = requests.get(url, params=params)

if response.status_code == 200:
    response_json = response.json()
    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(script_dir, "response.json")

    with open(file_path, "w", encoding="utf-8") as file:
        json.dump(response_json, file, ensure_ascii=False, indent=4)
    print(f"Response saved to {file_path}")
else:
    print("Error:", response.status_code, response.text)