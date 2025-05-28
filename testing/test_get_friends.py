import requests

url = "http://127.0.0.1:5001/traintribe-f2c7b/us-central1/get_event_trip_friends"

params = {
    "event_options_path": "maps/events/event_options_Nvb5wS3IrKxWYcOZ2HLMdBQGEYzN_8jA7NBd1D96J4Cy98I9I.json",
    "user_id": "gXngi9sItqoTrlKjwbbdQr30prNn",
    "date": "2025-05-13"
}
response = requests.get(url, params=params)
if response.status_code == 200:
    print(response)
else:
    print("Error:", response.status_code, response.text)
