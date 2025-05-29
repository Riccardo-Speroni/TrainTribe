import requests
import json

url = "http://127.0.0.1:5001/traintribe-f2c7b/us-central1/get_event_full_trip_data"

params = {
    "user_id": "pwgIShdGUgRhsyi0ss5wtRWaKQ7P",
    "date": "2025-05-29"
}
response = requests.get(url, params=params)
if response.status_code == 200:
    with open("response.json", "w", encoding="utf-8") as f:
        json.dump(response.json(), f, ensure_ascii=False, indent=2)
else:
    print("Error:", response.status_code, response.text)
