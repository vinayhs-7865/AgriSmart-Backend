from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd
import requests
from datetime import datetime
import os
from dotenv import load_dotenv

app = FastAPI()

# ==============================
# Load Environment
# ==============================
load_dotenv()
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

if not GOOGLE_MAPS_API_KEY:
    raise Exception("Google Maps API key missing in .env")

FIREBASE_URL = "https://agrismart-iot-2a69a-default-rtdb.asia-southeast1.firebasedatabase.app"

# ==============================
# Load ML Models
# ==============================
category_model = joblib.load("final_crop_category_classifier.pkl")
price_model = joblib.load("price_prediction_model.pkl")

# ==============================
# Valid Inputs
# ==============================
VALID_SOILS = ["Red Soil", "Black Soil", "Coastal Alluvial Soil"]
VALID_WATER = ["Low", "Moderate", "High"]

# ==============================
# Crop Database
# ==============================
crop_database = {
    "Cereals": {
        "Rice":{"N":80,"P":40,"K":40,"base_yield":4.0,"cost_per_acre":25000},
        "Wheat":{"N":70,"P":35,"K":30,"base_yield":3.5,"cost_per_acre":22000},
        "Maize":{"N":90,"P":45,"K":40,"base_yield":5.0,"cost_per_acre":20000}
    },
    "Vegetables": {
        "Tomato":{"N":100,"P":50,"K":50,"base_yield":6.0,"cost_per_acre":60000},
        "Onion":{"N":80,"P":40,"K":40,"base_yield":5.5,"cost_per_acre":55000},
        "Potato":{"N":110,"P":60,"K":60,"base_yield":7.0,"cost_per_acre":65000}
    },
    "Fruits": {
        "Mango":{"N":60,"P":30,"K":30,"base_yield":8.0,"cost_per_acre":80000},
        "Banana":{"N":120,"P":60,"K":60,"base_yield":10.0,"cost_per_acre":90000}
    },
    "Pulses": {
        "Red Gram":{"N":40,"P":20,"K":20,"base_yield":2.5,"cost_per_acre":18000}
    },
    "Cash Crops": {
        "Sugarcane":{"N":150,"P":75,"K":75,"base_yield":12.0,"cost_per_acre":70000}
    }
}

# ==============================
# Input Schema
# ==============================
class FarmerInput(BaseModel):
    location: str
    soil_type: str
    water: str
    land_size: float
    budget: float

# ==============================
# Utility Functions
# ==============================
def get_sensor_data():
    try:
        url = f"{FIREBASE_URL}/sensor_data.json"
        response = requests.get(url)
        data = response.json()
        return data["temperature"], data["humidity"], data["soil_moisture"]
    except:
        raise HTTPException(status_code=500, detail="Failed to fetch IoT sensor data")

def get_lat_lon(location):
    url = f"https://maps.googleapis.com/maps/api/geocode/json?address={location}&key={GOOGLE_MAPS_API_KEY}"
    res = requests.get(url).json()

    if res.get("status") != "OK":
        raise HTTPException(status_code=400, detail="Invalid location")

    loc = res["results"][0]["geometry"]["location"]
    return loc["lat"], loc["lng"]

def get_district(lat, lon):
    url = f"https://maps.googleapis.com/maps/api/geocode/json?latlng={lat},{lon}&key={GOOGLE_MAPS_API_KEY}"
    res = requests.get(url).json()
    for r in res.get("results", []):
        for comp in r.get("address_components", []):
            if "administrative_area_level_2" in comp["types"]:
                return comp["long_name"]
    return "Unknown"

def get_season():
    m = datetime.now().month
    if m in [6,7,8,9]:
        return "Kharif"
    elif m in [10,11,12,1,2]:
        return "Rabi"
    else:
        return "Summer"

# ==============================
# Prediction Endpoint
# ==============================
@app.post("/predict")
def predict(data: FarmerInput):

    # Validate Soil
    if data.soil_type not in VALID_SOILS:
        raise HTTPException(status_code=400, detail="Invalid soil type")

    # Validate Water
    if data.water not in VALID_WATER:
        raise HTTPException(status_code=400, detail="Invalid water level")

    temperature, humidity, soil_moisture = get_sensor_data()

    # NPK estimation from soil moisture
    if soil_moisture < 30:
        N, P, K = 40, 20, 20
    elif soil_moisture < 60:
        N, P, K = 70, 35, 35
    else:
        N, P, K = 100, 50, 50

    lat, lon = get_lat_lon(data.location)
    district = get_district(lat, lon)
    season = get_season()

    min_temp = temperature - 3
    max_temp = temperature + 3
    temp_range = max_temp - min_temp
    npk_total = N + P + K

    input_df = pd.DataFrame([{
        "DISTRICTS": district,
        "SOIL_TYPE": data.soil_type,
        "SEASONS": season,
        "WATER_REQ": data.water,
        "Min_Temp": min_temp,
        "Max_Temp": max_temp,
        "Ideal_Hum": humidity,
        "N": N,
        "P": P,
        "K": K,
        "Temp_Range": temp_range,
        "NPK_Total": npk_total
    }])

    predicted_category = category_model.predict(input_df)[0]

    best_roi = -999999
    best_result = None

    HECTARE_TO_ACRE = 2.471
    TON_TO_QUINTAL = 10

    for crop_name, vals in crop_database.get(predicted_category, {}).items():

        total_cost = vals["cost_per_acre"] * data.land_size

        if data.budget < total_cost:
            continue

        ideal_total = vals["N"] + vals["P"] + vals["K"]
        score = abs(N - vals["N"]) + abs(P - vals["P"]) + abs(K - vals["K"])
        suitability = max(0, 100 - (score / ideal_total) * 100)

        yield_hectare = vals["base_yield"] * (npk_total / ideal_total)
        yield_per_acre = (yield_hectare / HECTARE_TO_ACRE) * TON_TO_QUINTAL
        total_yield = yield_per_acre * data.land_size

        # Safe price prediction
        try:
            price_df = pd.DataFrame([{
                "District": district,
                "Crop": crop_name
            }])
            predicted_price = float(price_model.predict(price_df)[0])
        except:
            predicted_price = 0.0

        revenue = total_yield * predicted_price
        profit = revenue - total_cost
        roi = (profit / total_cost) * 100 if total_cost != 0 else 0

        if profit > 0 and roi > best_roi:
            best_roi = roi
            best_result = {
                "farmer_input": {
                    "location": data.location,
                    "district": district,
                    "season": season,
                    "soil_type": data.soil_type,
                    "water_level": data.water,
                    "land_size_acres": data.land_size,
                    "budget": data.budget
                },
                "environment_data": {
                    "temperature": temperature,
                    "humidity": humidity,
                    "soil_moisture": soil_moisture,
                    "calculated_NPK": {"N": N, "P": P, "K": K}
                },
                "prediction": {
                    "recommended_crop": crop_name,
                    "predicted_category": predicted_category,
                    "suitability_percent": round(suitability, 2)
                },
                "financial_analysis": {
                    "price_per_quintal": round(predicted_price, 2),
                    "yield_per_acre_quintals": round(yield_per_acre, 2),
                    "total_yield_quintals": round(total_yield, 2),
                    "total_cost": round(total_cost, 2),
                    "expected_revenue": round(revenue, 2),
                    "net_profit": round(profit, 2),
                    "roi_percent": round(roi, 2)
                }
            }

    if not best_result:
        return {
            "message": "No profitable crop found within your budget under current conditions.",
            "predicted_category": predicted_category
        }

    return best_result


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app:app", host="0.0.0.0", port=10000)