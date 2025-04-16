from fastapi import FastAPI, HTTPException
from firebase_admin import credentials, firestore as admin_firestore, initialize_app
import tensorflow as tf
import logging
import os
import threading
import schedule
import time
import uvicorn

from ML_Model import (
    refresh_firestore_data_to_json,
    load_property_data,
    group_user_houses,
    load_or_train_model,
    retrain_global_model_only,
    generate_recommendations_for_user,
    save_all_user_property_scores_to_db,
    refresh_firestore_data_to_json_for_user
)

# ========== Firebase Setup ==========
cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json")
initialize_app(cred)
db = admin_firestore.client()

# ========== FastAPI Setup ==========
app = FastAPI()
logging.basicConfig(filename="server.log", level=logging.INFO)

# ========== Constants ==========
DATA_PATH = "db.json"
PER_USER_DATA_PATH = "user.json"

# ========== Utility ==========
def get_user_data(user_id: str):
    doc = db.collection("users").document(user_id).get()
    return doc.to_dict() if doc.exists else None

# ========== Endpoint: Health ==========
@app.get("/health")
def health_check():
    return {"status": "running"}

# ========== Endpoint: Get Recommendations ==========
@app.get("/recommendations/{user_id}")
def get_recommendations(user_id: str):
    print({user_id})
    try:
        logging.info(f"Generating recommendations for user {user_id}")

        user = get_user_data(user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        if "preferences" not in user:
            raise HTTPException(status_code=400, detail="User preferences missing")

        refresh_firestore_data_to_json_for_user(db, user_id, PER_USER_DATA_PATH)
        properties = load_property_data(PER_USER_DATA_PATH)
        user_houses = group_user_houses(properties)

        if user_id not in user_houses:
            raise HTTPException(status_code=404, detail="No interaction data for this user")

        model, scaler = load_or_train_model(user_houses)

        recommendations = generate_recommendations_for_user(
            user_id,
            properties,
            user_houses,
            model,
            scaler,
            behavior_weight=0.6,
            similar_user_weight=0.3,
            preference_weight=0.1
        )
        save_all_user_property_scores_to_db(recommendations)

        return {"recommendations": recommendations}

    except Exception as e:
        logging.error(f"Error generating recommendations for {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

# ========== Endpoint: Train Global Model + Generate Recommendations ==========
@app.post("/train-and-generate")
def train_and_generate_all():
    try:
        logging.info("Training global model and generating all user recommendations...")
        # refresh_firestore_data_to_json(DATA_PATH)
        refresh_firestore_data_to_json(db, DATA_PATH)


        from ML_Model import run_pipeline  
        run_pipeline(retrain_global=True)

        return {"message": "Global model retrained and recommendations generated for all users."}

    except Exception as e:
        logging.error(f"Error in /train-and-generate: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to train and generate recommendations")


# ========== Endpoint: Train Global Model ONLY ==========
@app.post("/train-global")
def train_global():
    try:
        logging.info("Starting global model retraining...")
        refresh_firestore_data_to_json(db, DATA_PATH)
        retrain_global_model_only()
        return {"message": "Global model retrained successfully"}
    except Exception as e:
        logging.error(f"Error retraining global model: {str(e)}")
        raise HTTPException(status_code=500, detail="Model retraining failed")

# ========== Scheduled Global Model Retraining ==========
def scheduled_training():
    try:
        logging.info("Scheduled global retraining triggered")
        retrain_global_model_only()
        logging.info("Scheduled global retraining complete")
    except Exception as e:
        logging.error(f"Scheduled training error: {str(e)}")

schedule.every().day.at("04:00").do(scheduled_training)

def schedule_runner():
    while True:
        schedule.run_pending()
        time.sleep(60)

threading.Thread(target=schedule_runner, daemon=True).start()

# ========== Server Entrypoint ==========
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
