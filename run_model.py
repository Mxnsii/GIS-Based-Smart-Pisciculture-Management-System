import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import pickle
import time

# 🔹 Firebase setup
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# 🔹 Load model
model = pickle.load(open("fish_model.pkl", "rb"))
le_species = pickle.load(open("species_encoder.pkl", "rb"))
le_label = pickle.load(open("label_encoder.pkl", "rb"))

# 🔹 Unsafe check
def is_unsafe(row):
    if row["temperature"] > 30: return True
    if row["pH"] < 6.5 or row["pH"] > 9: return True
    if row["turbidity"] > 25: return True
    return False

# 🔹 Alert logic
def check_consecutive_unsafe(df, n=3):
    if len(df) < n:
        return False
    
    last_n = df.tail(n)
    
    unsafe_count = sum(is_unsafe(row) for _, row in last_n.iterrows())
    
    return unsafe_count >= (0.8 * n)

# 🔹 Prediction
def predict_risk(row):
    
    species = "Tilapia"  # default (since not in data)
    species_encoded = le_species.transform([species])[0]

    features = [[
        species_encoded,
        row["pH"],
        row["temperature"],
        row["turbidity"]
    ]]

    pred = model.predict(features)
    
    return le_label.inverse_transform(pred)[0]

# 🔁 MAIN LOOP
while True:
    try:
        docs = db.collection("water_parameters").stream()

        data_list = []
        for doc in docs:
            data = doc.to_dict()

            # Fix typo
            if "turbidty" in data:
                data["turbidity"] = data.pop("turbidty")

            data_list.append(data)

        df = pd.DataFrame(data_list)

        # Sort by timestamp
        df = df.sort_values("timestamp")

        latest = df.iloc[-1]

        # 🔹 Predict risk
        risk = predict_risk(latest)

        # 🔹 Alert check
        alert = check_consecutive_unsafe(df, 3)

        print("Risk:", risk)
        print("Alert:", alert)

        # 🔹 Update Firestore
        db.collection("results").document("latest").set({
            "risk": risk,
            "alert": alert
        })

        time.sleep(5)

    except Exception as e:
        print("Error:", e)