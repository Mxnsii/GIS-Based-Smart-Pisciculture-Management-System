import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import pickle
import time

# =========================================
# FIREBASE SETUP
# =========================================

cred = credentials.Certificate("firebase-key.json")

firebase_admin.initialize_app(cred)

db = firestore.client()

# =========================================
# LOAD TRAINED MODEL
# =========================================

model = pickle.load(open("fish_model.pkl", "rb"))
le_species = pickle.load(open("species_encoder.pkl", "rb"))
le_label = pickle.load(open("label_encoder.pkl", "rb"))

# =========================================
# SPECIES LIST
# =========================================

species_list = [
    "Whiteleg Shrimp",
    "Tiger Shrimp",
    "Tilapia",
    "Catfish",
    "Milkfish"
]

# =========================================
# MAIN LOOP
# =========================================

while True:

    try:

        # =================================
        # FETCH FIRESTORE DATA
        # =================================

        docs = db.collection("water_parameters").stream()

        data_list = []

        for doc in docs:

            data = doc.to_dict()

            # Fix typo if present
            if "turbidty" in data:
                data["turbidity"] = data.pop("turbidty")

            data_list.append(data)

        # =================================
        # CONVERT TO DATAFRAME
        # =================================

        df = pd.DataFrame(data_list)

        # Sort by latest timestamp
        if "timestamp" in df.columns:
            df = df.sort_values("timestamp")

        latest = df.iloc[-1]

        # =================================
        # GET LATEST SENSOR VALUES
        # =================================

        temp = latest["temperature"]
        pH = latest["pH"]
        turbidity = latest["turbidity"]

        # If salinity sensor absent
        salinity = latest.get("salinity", 10)

        # =================================
        # STORE RESULTS
        # =================================

        results = {}

        # =================================
        # RUN FOR ALL SPECIES
        # =================================

        for species in species_list:

            # Encode species
            species_encoded = le_species.transform([species])[0]

            # ML Model Features
            features = [[
                species_encoded,
                temp,
                pH,
                salinity,
                turbidity
            ]]

            # Stress Prediction
            pred = model.predict(features)

            stress = le_label.inverse_transform(pred)[0]

            # =================================
            # SAVE SPECIES RESULT
            # =================================

            species_data = {
                "stress_level": stress
            }

            # =================================
            # SPECIAL WHITE SPOT LOGIC (SHRIMP ONLY)
            # =================================

            if species in ["Whiteleg Shrimp", "Tiger Shrimp"]:

                if temp < 27 or temp > 32:
                    white_spot_risk = "Elevated"

                elif salinity < 15:
                    white_spot_risk = "Moderate"

                else:
                    white_spot_risk = "Low"

                species_data["white_spot_risk"] = white_spot_risk

            results[species] = species_data

        # =================================
        # PRINT OUTPUT
        # =================================

        print("\n============================")
        print("LATEST ANALYSIS")
        print("============================")

        for species, value in results.items():

            print(f"\n{species}")

            print("Stress Level:",
                  value["stress_level"])

            if "white_spot_risk" in value:
                print("White Spot Risk:",
                      value["white_spot_risk"])

        # =================================
        # UPDATE FIRESTORE
        # =================================

        db.collection("results").document("latest").set(results)

        print("\nFirestore Updated Successfully")

        # =================================
        # WAIT 5 SECONDS
        # =================================

        time.sleep(5)

    except Exception as e:

        print("Error:", e)