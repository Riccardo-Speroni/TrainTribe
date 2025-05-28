import json
from bucket_manager import download_from_bucket, upload_to_bucket
import tempfile
import os
from firebase_admin import firestore

def get_event_trip_friends_logic(params):

    event_options_path = params.get("event_options_path")
    user_id = params.get("user_id")
    bucket_name = params.get("bucket_name")
    date = params.get("date")

    db = firestore.Client()
    user_doc = db.collection("users").document(user_id).get()
    friends = []
    if user_doc.exists:
        friends_map = user_doc.to_dict().get("friends", {})
        for friend_id, friend_info in friends_map.items():
            # Check if the user ghosted the friend
            user_ghosted_friend = friend_info.get("ghosted", False)
            # Check if the friend ghosted the user
            friend_doc = db.collection("users").document(friend_id).get()
            friend_ghosted_user = False
            if friend_doc.exists:
                friend_friends_map = friend_doc.to_dict().get("friends", {})
                friend_ghosted_user = friend_friends_map.get(user_id, {}).get("ghosted", False)
            if not user_ghosted_friend and not friend_ghosted_user:
                friends.append(friend_id)

    print (f"Found {len(friends)} friends for user {user_id}.")
    for friend_id in friends:
        print(f"Processing friend {friend_id}...")

    tmp_path = os.path.join(tempfile.gettempdir(), os.path.basename(event_options_path))
    download_from_bucket(bucket_name, event_options_path, tmp_path)
    with open(tmp_path, "r", encoding="utf-8") as f:
        event_routes = json.load(f)

    for route in event_routes:
        for leg in route.get("legs", []):
            friends_on_trip = check_friends_on_trip(leg.get("trip_id"), friends, date)
            if friends_on_trip:
                leg["friends"] = friends_on_trip
    
    # Save the modified event_routes to a new file and upload it
    new_event_options_path = event_options_path + "_with_friends"
    new_tmp_path = os.path.join(tempfile.gettempdir(), os.path.basename(new_event_options_path))
    with open(new_tmp_path, "w", encoding="utf-8") as f:
        json.dump(event_routes, f, ensure_ascii=False, indent=2)
    upload_to_bucket(bucket_name, new_tmp_path, new_event_options_path)

    return new_event_options_path

def check_friends_on_trip(trip_id, friends, date):
    db = firestore.Client()
    
    users_on_trip = db.collection("trains_matches").document(date).collection("trains").document(trip_id).collection("users").get()
    friends_on_trip = []
    for user_on_trip in users_on_trip:
        if user_on_trip.id in friends:
            user = db.collection("users").document(user_on_trip.id).get().to_dict()
            name = user.get("Username", "Unknown")
            picture = user.get("picture", "")
            friend = {
                "user_id": user_on_trip.id,
                "username": name,
                "picture": picture,
                "from": user_on_trip.get("from", ""),
                "to": user_on_trip.get("to", ""),
                "confirmed": user_on_trip.get("confirmed", False)
            }
            friends_on_trip.append(friend)