import pandas as pd
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib

# Load dataset
df = pd.read_csv("AI_Scientific_Master_Data.csv")

# -----------------------------
# Crop Category Mapping
# -----------------------------
def map_crop(crop):
    cereals = ["Rice", "Paddy(Common)", "Paddy(Basmati)", "Wheat", "Maize",
               "Jowar(Sorghum)", "Bajra(Pearl Millet/Cumbu)", "Millets"]

    pulses = ["Red Gram", "Green Peas", "Beans",
              "White Peas", "Surat Beans(Papadi)",
              "Sesamum(Sesame,Gingelly,Til)",
              "Groundnut", "Mustard"]   # merged Oilseeds here

    vegetables = ["Tomatao", "Onion", "Potato", "Brinjal", "Cabbage",
                  "Cauliflower", "Carrot", "Capsicum",
                  "Bhindi(Ladies Finger)", "Bottle gourd",
                  "Bitter gourd", "Ridgegourd(Tori)",
                  "Snakegourd", "Pumpkin", "Sweet Pumpkin",
                  "Sponge gourd", "Spinach",
                  "Thondekai", "Seemebadnekai"]

    fruits = ["Mango", "Banana", "Papaya", "Guava",
              "Orange", "Lemon", "Pineapple",
              "Pomegranate", "Water Melon",
              "Karbuja(Musk Melon)", "Coconut",
              "Tender Coconut"]

    cash = ["Sugarcane", "Rubber", "Jute"]

    if crop in cereals:
        return "Cereals"
    elif crop in pulses:
        return "Pulses"
    elif crop in vegetables:
        return "Vegetables"
    elif crop in fruits:
        return "Fruits"
    elif crop in cash:
        return "Cash Crops"
    else:
        return "Others"

# Create category column
df["CROP_CATEGORY"] = df["COMMODITIES"].apply(map_crop)

# Remove weak class
df = df[df["CROP_CATEGORY"] != "Others"]

# -----------------------------
# Feature Engineering
# -----------------------------
df["Temp_Range"] = df["Max_Temp"] - df["Min_Temp"]
df["NPK_Total"] = df["N"] + df["P"] + df["K"]

# Features & target
X = df.drop(["COMMODITIES", "CROP_CATEGORY"], axis=1)
y = df["CROP_CATEGORY"]

categorical_cols = ["DISTRICTS", "SOIL_TYPE", "SEASONS", "WATER_REQ"]
numerical_cols = ["Min_Temp", "Max_Temp", "Ideal_Hum",
                  "N", "P", "K",
                  "Temp_Range", "NPK_Total"]

preprocessor = ColumnTransformer(
    transformers=[
        ("cat", OneHotEncoder(handle_unknown="ignore"), categorical_cols),
        ("num", "passthrough", numerical_cols)
    ]
)

rf = RandomForestClassifier(
    n_estimators=400,
    class_weight="balanced",
    random_state=42,
    n_jobs=-1
)

model = Pipeline(steps=[
    ("preprocessor", preprocessor),
    ("classifier", rf)
])

X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    stratify=y,
    random_state=42
)

model.fit(X_train, y_train)

cv_scores = cross_val_score(model, X_train, y_train, cv=5)

y_pred = model.predict(X_test)

print("Test Accuracy:", accuracy_score(y_test, y_pred))
print("Cross Validation Accuracy:", cv_scores.mean())
print("\nClassification Report:\n", classification_report(y_test, y_pred))
print("\nConfusion Matrix:\n", confusion_matrix(y_test, y_pred))

joblib.dump(model, "final_crop_category_classifier.pkl")