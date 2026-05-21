# =========================================================
# SMART AQUACULTURE SPECIES RECOMMENDATION SYSTEM
# =========================================================
#
# Features:
# - Synthetic dataset generation
# - Multiple ML model comparison
# - Water type feature engineering
# - Ranked species recommendations
# - Suitability levels
# - Feature importance
# - Model saving
#
# Species:
# 1. Whiteleg Shrimp
# 2. Tiger Shrimp
# 3. Tilapia
# 4. Catfish
# 5. Milkfish
#
# Sensors:
# - Temperature
# - pH
# - Salinity
# - Turbidity
#
# =========================================================

import random
import pandas as pd
import numpy as np
import joblib

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import accuracy_score

from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import (
    RandomForestClassifier,
    GradientBoostingClassifier
)

from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC

# =========================================================
# STEP 1: DEFINE SPECIES WATER QUALITY RANGES
# =========================================================

species_ranges = {

    "Whiteleg Shrimp": {
        "temp": (28, 32),
        "ph": (7.5, 8.5),
        "salinity": (15, 25),
        "turbidity": (20, 50)
    },

    "Tiger Shrimp": {
        "temp": (27, 31),
        "ph": (7.5, 8.5),
        "salinity": (15, 30),
        "turbidity": (25, 55)
    },

    "Tilapia": {
        "temp": (24, 30),
        "ph": (6.5, 8.5),
        "salinity": (0, 5),
        "turbidity": (10, 30)
    },

    "Catfish": {
        "temp": (25, 32),
        "ph": (6.5, 8),
        "salinity": (0, 8),
        "turbidity": (15, 40)
    },

    "Milkfish": {
        "temp": (26, 32),
        "ph": (7, 8.5),
        "salinity": (10, 35),
        "turbidity": (20, 45)
    }
}

# =========================================================
# STEP 2: WATER TYPE FUNCTION
# =========================================================

def get_water_type(salinity):

    if salinity <= 5:
        return "Freshwater"

    elif salinity <= 15:
        return "Brackish"

    else:
        return "High Salinity"

# =========================================================
# STEP 3: GENERATE SYNTHETIC DATASET
# =========================================================

data = []

# Increase dataset size
rows_per_species = 1200

for species, ranges in species_ranges.items():

    for _ in range(rows_per_species):

        # Generate values inside ranges
        temp = random.uniform(*ranges["temp"])
        ph = random.uniform(*ranges["ph"])
        salinity = random.uniform(*ranges["salinity"])
        turbidity = random.uniform(*ranges["turbidity"])

        # Add realistic noise
        temp += random.uniform(-1, 1)
        ph += random.uniform(-0.3, 0.3)
        salinity += random.uniform(-2, 2)
        turbidity += random.uniform(-5, 5)

        # Avoid negative values
        salinity = max(0, salinity)
        turbidity = max(0, turbidity)

        # Round values
        temp = round(temp, 2)
        ph = round(ph, 2)
        salinity = round(salinity, 2)
        turbidity = round(turbidity, 2)

        # Water type feature
        water_type = get_water_type(salinity)

        # Append row
        data.append([
            temp,
            ph,
            salinity,
            turbidity,
            water_type,
            species
        ])

# =========================================================
# STEP 4: CREATE DATAFRAME
# =========================================================

df = pd.DataFrame(data, columns=[
    "temperature",
    "pH",
    "salinity",
    "turbidity",
    "water_type",
    "species"
])

# Shuffle dataset
df = df.sample(frac=1).reset_index(drop=True)

# Save dataset
df.to_csv("aquaculture_species_dataset.csv", index=False)

print("\nDataset Generated Successfully!\n")

print(df.head())

# =========================================================
# STEP 5: ENCODE WATER TYPE
# =========================================================

water_encoder = LabelEncoder()

df["water_type"] = water_encoder.fit_transform(
    df["water_type"]
)

# =========================================================
# STEP 6: PREPARE FEATURES & LABELS
# =========================================================

X = df[[
    "temperature",
    "pH",
    "salinity",
    "turbidity",
    "water_type"
]]

y = df["species"]

# Encode target labels
species_encoder = LabelEncoder()

y_encoded = species_encoder.fit_transform(y)

# =========================================================
# STEP 7: TRAIN TEST SPLIT
# =========================================================

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y_encoded,
    test_size=0.2,
    random_state=42
)

# =========================================================
# STEP 8: DEFINE MODELS
# =========================================================

models = {

    "Decision Tree": DecisionTreeClassifier(),

    "Random Forest": RandomForestClassifier(
        n_estimators=300,
        max_depth=10,
        min_samples_split=5,
        random_state=42
    ),

    "Gradient Boosting": GradientBoostingClassifier(),

    "KNN": KNeighborsClassifier(
        n_neighbors=5
    ),

    "SVM": SVC(
        probability=True
    )
}

# =========================================================
# STEP 9: TRAIN & EVALUATE MODELS
# =========================================================

best_model = None
best_accuracy = 0
best_model_name = ""

print("\n====================================")
print("MODEL COMPARISON")
print("====================================")

for name, model in models.items():

    # Train model
    model.fit(X_train, y_train)

    # Predict
    y_pred = model.predict(X_test)

    # Accuracy
    accuracy = accuracy_score(y_test, y_pred)

    print(f"\n{name} Accuracy: {accuracy * 100:.2f}%")

    # Save best model
    if accuracy > best_accuracy:

        best_accuracy = accuracy
        best_model = model
        best_model_name = name

# =========================================================
# STEP 10: BEST MODEL
# =========================================================

print("\n====================================")
print("BEST MODEL")
print("====================================")

print(f"\nBest Model: {best_model_name}")
print(f"Accuracy: {best_accuracy * 100:.2f}%")

# =========================================================
# STEP 11: FEATURE IMPORTANCE
# =========================================================

if best_model_name == "Random Forest":

    importance = best_model.feature_importances_

    feature_names = X.columns

    print("\n====================================")
    print("FEATURE IMPORTANCE")
    print("====================================")

    for feature, score in zip(feature_names, importance):

        print(f"{feature} --> {score:.4f}")

# =========================================================
# STEP 12: LIVE SENSOR INPUT
# =========================================================

print("\n====================================")
print("LIVE SPECIES RECOMMENDATION")
print("====================================")

# Example live sensor values
temperature = 29.5
ph = 7.8
salinity = 20
turbidity = 35

# Convert salinity to water type
water_type = get_water_type(salinity)

# Encode water type
encoded_water_type = water_encoder.transform(
    [water_type]
)[0]

# Final input
sample_input = [[
    temperature,
    ph,
    salinity,
    turbidity,
    encoded_water_type
]]

# =========================================================
# STEP 13: PREDICT PROBABILITIES
# =========================================================

probabilities = best_model.predict_proba(sample_input)[0]

# Combine species names with probabilities
species_probabilities = list(zip(
    species_encoder.classes_,
    probabilities
))

# Sort descending
species_probabilities.sort(
    key=lambda x: x[1],
    reverse=True
)

# =========================================================
# STEP 14: DISPLAY RECOMMENDATIONS
# =========================================================

print("\nRecommended Species:\n")

rank = 1

for species, prob in species_probabilities:

    score = prob * 100

    # Ignore very low scores
    if score < 20:
        continue

    # Suitability labels
    if score >= 85:
        status = "Highly Suitable"

    elif score >= 70:
        status = "Suitable"

    elif score >= 50:
        status = "Moderately Suitable"

    else:
        status = "Low Suitability"

    print(
        f"{rank}. {species} --> "
        f"{score:.2f}% ({status})"
    )

    rank += 1

# =========================================================
# STEP 15: SAVE MODELS
# =========================================================

joblib.dump(
    best_model,
    "species_prediction_model.pkl"
)

joblib.dump(
    species_encoder,
    "species_label_encoder.pkl"
)

joblib.dump(
    water_encoder,
    "water_type_encoder.pkl"
)

print("\nBest model saved successfully!")

# =========================================================
# END
# =========================================================
joblib.dump(
    best_model,
    "species_prediction_model.pkl"
)

joblib.dump(
    species_encoder,
    "species_label_encoder.pkl"
)

joblib.dump(
    water_encoder,
    "water_type_encoder.pkl"
)
