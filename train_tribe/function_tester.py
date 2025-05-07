import requests

url = "https://get-trip-options-v75np53hva-uc.a.run.app"
params = {
    "origin": "Brescia",
    "destination": "Milano Porta Garibaldi",
    "arrival_time": "2023-12-01 10:00"
}

response = requests.get(url, params=params)

if response.status_code == 200:
    print("Success:", response.json())
else:
    print("Error:", response.status_code, response.text)