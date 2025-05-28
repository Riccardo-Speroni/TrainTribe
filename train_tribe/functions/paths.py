bucket_name = "traintribe-f2c7b.firebasestorage.app"
jsonified_trenord_data_path = "maps/full_info_trips.json"
full_legs_partial_path = "maps/results/full_info_legs"
maps_response_partial_path = "maps/responses/maps_response"
event_options_partial_path = "maps/events/event_options"

def get_full_legs_full_path(id):
    return full_legs_partial_path + str(id) + ".json"

def get_maps_response_full_path(id):
    return maps_response_partial_path + str(id) + ".json"

def get_event_options_full_path(id):
    return event_options_partial_path + str(id) + ".json"

