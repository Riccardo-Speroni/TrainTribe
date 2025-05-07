from google.cloud import storage

def upload_to_bucket(source_file, destination_blob, bucket_name):
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(destination_blob)
    blob.upload_from_filename(source_file)
    print(f"File {source_file} uploaded as {destination_blob} in bucket {bucket_name}")


def download_from_bucket(bucket_name, blob_name, destination_path):
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(destination_path)
    print(f"File {blob_name} downloaded to {destination_path}")