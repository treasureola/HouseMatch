from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from google.cloud import firestore
from firebase_admin import credentials, firestore as admin_firestore, initialize_app
import tensorflow as tf
import numpy as np
import logging
import os
import threading
import schedule
import time
import uvicorn

from ML_Model import (
    load_property_data,
    group_user_houses,
    train_global_model,
    load_scaler,
    generate_weighted_recommendations,
    run_pipeline
)

# ========== Firebase + Firestore Setup ==========
cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json")
initialize_app(cred)
db = admin_firestore.client()

# ========== FastAPI Setup ==========
app = FastAPI()
logging.basicConfig(filename="server.log", level=logging.INFO)

# ========== Constants ==========
DATA_PATH = "db.json"  # Firestore-exported data
global_model_path = "global_model.h5"
scaler_path = "scaler.npy"

# ========== Helper Function ==========
def get_user_data(user_id: str):
    user_doc = db.collection("users").document(user_id).get()
    if not user_doc.exists:
        return None
    return user_doc.to_dict()

# ========== Recommendation Endpoint ==========
@app.get("/recommendations/{user_id}")
def get_recommendations(user_id: str):
    try:
        logging.info(f"Generating recommendations for user: {user_id}")

        user = get_user_data(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        if "preferences" not in user:
            raise HTTPException(status_code=400, detail="User preferences not found. Please complete your preferences in the app.")

        properties = load_property_data(DATA_PATH)
        user_houses = group_user_houses(properties)

        if not os.path.exists(global_model_path):
            model, scaler = train_global_model(user_houses)
        else:
            model = tf.keras.models.load_model(global_model_path)
            scaler = load_scaler()

        all_recommendations = generate_weighted_recommendations(
            properties,
            user_houses,
            model,
            scaler,
            behavior_weight=0.6,
            similar_user_weight=0.2,
            preference_weight=0.2
        )

        recommendations = all_recommendations.get(user_id, {})

        db.collection("recommendations").document(user_id).set({
            "user_id": user_id,
            "recommendations": recommendations,
            "timestamp": admin_firestore.SERVER_TIMESTAMP
        })

        return {"recommendations": recommendations}

    except Exception as e:
        logging.error(f"Error generating recommendations: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# ========== Optional: Trigger model retraining ==========
@app.post("/train")
def retrain_model():
    try:
        run_pipeline(retrain_global=True)
        return {"message": "Global model retrained successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ========== Scheduled Model Retraining ==========
def scheduled_training():
    logging.info("Scheduled training triggered.")
    run_pipeline(retrain_global=True)

# Schedule retraining every day at 2:00 AM
schedule.every().day.at("12:00").do(scheduled_training)

def schedule_runner():
    while True:
        schedule.run_pending()
        time.sleep(60)

threading.Thread(target=schedule_runner, daemon=True).start()

# ========== Health Check ==========
@app.get("/health")
def health():
    return {"status": "running"}

# ========== Run Server ==========
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
