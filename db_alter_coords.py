from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from datetime import datetime

app = Flask(__name__)

app.config["MONGO_URI"] = "mongodb://localhost:27017/test_coords"
mongo = PyMongo(app)

coords_collection = mongo.db.coords_data


@app.route('/save-coords', methods=['POST'])
def save_coords():
    try:
        data = request.get_json()

     
        lat = data.get('lat')
        lng = data.get('lng')
        notes = data.get('notes')

    
        coords = {
            'lat': lat,
            'lng': lng,
            'notes': notes,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow()
        }

    
        coords_collection.insert_one(coords)

        return jsonify({"message": "Coordinates saved successfully!", "data": coords}), 201

    except Exception as e:
        return jsonify({"message": "Failed to save coordinates", "error": str(e)}), 500


@app.route('/coords', methods=['GET'])
def get_coords():
    try:
        coords_data = list(coords_collection.find())

        for coord in coords_data:
            coord['_id'] = str(coord['_id'])

        return jsonify(coords_data), 200

    except Exception as e:
        return jsonify({"message": "Failed to fetch coordinates", "error": str(e)}), 500
        
if __name__ == '__main__':
    app.run(debug=True, port=3000)
