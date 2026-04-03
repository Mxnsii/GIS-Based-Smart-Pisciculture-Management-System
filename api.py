from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import numpy as np

app = Flask(__name__)
CORS(app) # crucial to bypass Flutter Web browser security blocks!

# Load model and encoders
model = pickle.load(open("fish_model.pkl", "rb"))
le_species = pickle.load(open("species_encoder.pkl", "rb"))
le_label = pickle.load(open("label_encoder.pkl", "rb"))

@app.route("/")
def home():
    return "Fish Disease Prediction API Running"

@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json()

    species = data["species"]
    temperature = data["temperature"]
    pH = data["pH"]
    turbidity = data["turbidity"]
    do = data["do"]

    # Encode species
    species_encoded = le_species.transform([species])[0]

    # Prepare input
    features = np.array([[species_encoded, temperature, pH, turbidity, do]])

    # Predict
    prediction = model.predict(features)
    result = le_label.inverse_transform(prediction)[0]

    return jsonify({
        "prediction": result
    })

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)