import requests
import os

# Cloud Function URL
url = "https://call-jsonify-v75np53hva-uc.a.run.app"

# Emulator URL
# url = "http://127.0.0.1:5001/traintribe-f2c7b/us-central1/call_jsonify"

response = requests.get(url)

if response.status_code == 200:
    response_text = response.text
    print("Response:", response_text)

    # Get the directory of the current script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    file_path = os.path.join(script_dir, "jsonify_response.txt")

    with open(file_path, "w", encoding="utf-8") as file:
        file.write(response_text)
    print(f"Response saved to {file_path}")
else:
    print("Error:", response.status_code, response.text)