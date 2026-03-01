import joblib
import pandas as pd
import requests
from datetime import datetime
from dotenv import load_dotenv
import os

# ==============================
# Load Environment
# ==============================
load_dotenv()
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

if not GOOGLE_MAPS_API_KEY:
    raise Exception("Google Maps API key missing")

# ==============================
# Firebase URL
# ==============================
FIREBASE_URL = "https://agrismart-iot-2a69a-default-rtdb.asia-southeast1.firebasedatabase.app"

def get_sensor_data():
    url = f"{FIREBASE_URL}/sensor_data.json"
    response = requests.get(url)

    if response.status_code == 200:
        data = response.json()
        return data["temperature"], data["humidity"], data["soil_moisture"]
    else:
        raise Exception("Failed to fetch sensor data")

# ==============================
# Load Models
# ==============================
category_model = joblib.load("final_crop_category_classifier.pkl")
price_model = joblib.load("price_prediction_model.pkl")

# ==============================
# Maps API
# ==============================
def get_lat_lon(location):
    url = f"https://maps.googleapis.com/maps/api/geocode/json?address={location}&key={GOOGLE_MAPS_API_KEY}"
    res = requests.get(url).json()
    loc = res["results"][0]["geometry"]["location"]
    return loc["lat"], loc["lng"]

def get_district(lat, lon):
    url = f"https://maps.googleapis.com/maps/api/geocode/json?latlng={lat},{lon}&key={GOOGLE_MAPS_API_KEY}"
    res = requests.get(url).json()
    for r in res["results"]:
        for comp in r["address_components"]:
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
# Estimate NPK from Soil Moisture
# ==============================
def estimate_npk(soil_moisture):
    if soil_moisture < 30:
        return 40, 20, 20
    elif soil_moisture < 60:
        return 70, 35, 35
    else:
        return 100, 50, 50

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
# USER INPUT
# ==============================
location = input("Enter Location (Village/City): ")
soil = input("Enter Soil Type: ")
water = input("Enter Water Availability (Low/Medium/High): ")

land_size = float(input("Enter Total Land Size (acres): "))
user_budget = float(input("Enter Your Available Budget (₹): "))

# ==============================
# IoT Data
# ==============================
temperature, humidity, soil_moisture = get_sensor_data()

print("\n🌡 Live IoT Data")
print("Temperature:", temperature)
print("Humidity:", humidity)
print("Soil Moisture:", soil_moisture, "%")

N, P, K = estimate_npk(soil_moisture)

# ==============================
# Location Processing
# ==============================
lat, lon = get_lat_lon(location)
district = get_district(lat, lon)
season = get_season()

min_temp = temperature - 3
max_temp = temperature + 3
temp_range = max_temp - min_temp
npk_total = N + P + K

# ==============================
# Category Prediction
# ==============================
input_df = pd.DataFrame([{
    "DISTRICTS": district,
    "SOIL_TYPE": soil,
    "SEASONS": season,
    "WATER_REQ": water,
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
print("\n🌾 Predicted Category:", predicted_category)

# ==============================
# Financial Optimization
# ==============================
HECTARE_TO_ACRE = 2.471
TON_TO_QUINTAL = 10

best_crop = None
best_roi = -999999
best_result = {}

for crop, vals in crop_database[predicted_category].items():

    cost_total = vals["cost_per_acre"] * land_size

    if user_budget < cost_total:
        continue

    ideal_total = vals["N"]+vals["P"]+vals["K"]
    yield_hectare = vals["base_yield"]*(npk_total/ideal_total)
    yield_per_acre = (yield_hectare/HECTARE_TO_ACRE)*TON_TO_QUINTAL
    total_yield = yield_per_acre * land_size

    price_df = pd.DataFrame([{
        "District": district,
        "Crop": crop
    }])

    predicted_price = price_model.predict(price_df)[0]

    revenue = total_yield * predicted_price
    profit = revenue - cost_total
    roi = (profit / cost_total) * 100

    if profit > 0 and roi > best_roi:
        best_roi = roi
        best_crop = crop
        best_result = {
            "yield_per_acre": round(yield_per_acre,2),
            "predicted_price": round(predicted_price,2),
            "total_yield": round(total_yield,2),
            "total_cost": round(cost_total,2),
            "revenue": round(revenue,2),
            "profit": round(profit,2),
            "roi": round(roi,2)
        }

# ==============================
# Final Output
# ==============================
if best_crop:
    print("\n🏆 FINAL RECOMMENDED CROP:", best_crop)
    print("Yield per acre:", best_result["yield_per_acre"], "quintals")
    print("Predicted Price:", best_result["predicted_price"], "₹/quintal")
    print("Total Yield:", best_result["total_yield"], "quintals")
    print("Total Cost: ₹", best_result["total_cost"])
    print("Revenue: ₹", best_result["revenue"])
    print("Profit: ₹", best_result["profit"])
    print("ROI:", best_result["roi"], "%")
else:
    print("\n❌ No profitable crop within your budget.")