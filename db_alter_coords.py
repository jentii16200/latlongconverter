from pymongo import MongoClient, ASCENDING
from datetime import datetime

client = MongoClient('mongodb://localhost:27017/')
db = client.test_coords


collection = db.coords_data
collection.create_index([("lat", ASCENDING)])
collection.create_index([("lng", ASCENDING)])

# Example of adding a document
example_doc = {
    "id": 1,
    "notes": "Sample Coordinate",
    "lat": 14.5535,
    "lng": 121.0452,
    "created_at": datetime.now(),
    "updated_at": datetime.now()
}
collection.insert_one(example_doc)

print("Database and collection created successfully.")
