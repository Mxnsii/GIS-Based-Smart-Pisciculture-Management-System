from flask import Flask, request, jsonify
from flask_cors import CORS
import pickle
import joblib
import numpy as np

app = Flask(__name__)
CORS(app) # crucial to bypass Flutter Web browser security blocks!

# Load disease models and encoders
model = pickle.load(open("fish_model.pkl", "rb"))
le_species = pickle.load(open("species_encoder.pkl", "rb"))
le_label = pickle.load(open("label_encoder.pkl", "rb"))

# Load species recommendation models and encoders
try:
    species_rec_model = joblib.load("species_prediction_model.pkl")
    species_rec_label_encoder = joblib.load("species_label_encoder.pkl")
    water_type_encoder = joblib.load("water_type_encoder.pkl")
except Exception as e:
    print(f"Warning: Species recommendation models not found. {e}")


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

def get_water_type(salinity):
    if salinity <= 5:
        return "Freshwater"
    elif salinity <= 15:
        return "Brackish"
    else:
        return "High Salinity"

@app.route("/predict_species", methods=["POST"])
def predict_species():
    try:
        data = request.get_json()

        temperature = data["temperature"]
        ph = data["pH"]
        salinity = data["salinity"]
        turbidity = data["turbidity"]

        # 1. Determine water type
        water_type_str = get_water_type(salinity)
        
        # 2. Encode water type
        encoded_water_type = water_type_encoder.transform([water_type_str])[0]

        # 3. Final input for Random Forest
        sample_input = [[temperature, ph, salinity, turbidity, encoded_water_type]]

        # 4. Predict probabilities
        probabilities = species_rec_model.predict_proba(sample_input)[0]

        # 5. Combine and sort
        species_probabilities = list(zip(species_rec_label_encoder.classes_, probabilities))
        species_probabilities.sort(key=lambda x: x[1], reverse=True)

        # 6. Format the response
        results = []
        for species, prob in species_probabilities:
            score = prob * 100
                
            if score >= 85:
                status = "Highly Suitable"
            elif score >= 70:
                status = "Suitable"
            elif score >= 50:
                status = "Moderately Suitable"
            else:
                status = "Low Suitability"
                
            results.append({
                "species": species,
                "score": round(score, 2),
                "status": status
            })

        return jsonify({
            "recommendations": results
        })

    except Exception as e:
        print("Species Prediction Error:", e)
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)