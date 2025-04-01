from fastapi import FastAPI, HTTPException, BackgroundTasks
import json
import numpy as np
import pandas as pd
from pydantic import BaseModel
import uvicorn
import time
import logging
import redis
import threading
import schedule
from google.cloud import firestore
import firebase_admin
from firebase_admin import credentials, firestore
from curModel import get_recommendations  

# Initialize Firebase
cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-b37e56f837.json")  
firebase_admin.initialize_app(cred)

# Connect to Firestore
db = firestore.client()

# Initialize FastAPI
app = FastAPI()

# Configure Logging
logging.basicConfig(filename="server.log", level=logging.INFO)

# Connect to Redis
redis_client = redis.Redis(host="localhost", port=6379, db=0)

# ============================
#   ML-BASED HOUSE RECOMMENDATION
# ============================
@app.get("/recommendations/{user_id}")
def recommend_houses(user_id: str):
    try:
        logging.info(f"API called for user_id={user_id} at {time.strftime('%Y-%m-%d %H:%M:%S')}")

        # Retrieve user preferences
        user_ref = db.collection("users").document(user_id)
        user_data = user_ref.get()

        if not user_data.exists:
            raise HTTPException(status_code=404, detail="User not found")

        user_prefs = user_data.to_dict().get("preferences", [])

        # Retrieving the liked houses fromt he firebase databses 
        liked_houses_ref = db.collection("user_likes").document(user_id)
        liked_houses_doc = liked_houses_ref.get()
        liked_houses = liked_houses_doc.to_dict().get("liked_properties", []) if liked_houses_doc.exists else []

        # Call get_recommendations from curModel
        recommendations = get_recommendations(user_prefs or [], liked_houses)

        # Store recommendations in Firestore
        db.collection("recommendations").document(user_id).set({
            "user_id": user_id,
            "recommendations": recommendations,
            "timestamp": firestore.SERVER_TIMESTAMP
        })

        return {"recommendations": recommendations}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============================
#   USER MANAGEMENT ENDPOINTS
# ============================
class UserProfile(BaseModel):
    user_id: str
    name: str
    email: str
    preferences: list

@app.post("/users")
def create_user(profile: UserProfile):
    try:
        user_ref = db.collection("users").document(profile.user_id)
        user_ref.set({
            "name": profile.name,
            "email": profile.email,
            "preferences": profile.preferences,
            "created_at": firestore.SERVER_TIMESTAMP
        })
        return {"message": "User profile created successfully"}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/users/{user_id}")
def get_user(user_id: str):
    try:
        user_ref = db.collection("users").document(user_id)
        doc = user_ref.get()

        if doc.exists:
            return doc.to_dict()
        else:
            raise HTTPException(status_code=404, detail="User not found")

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============================
#   HEALTH CHECK ENDPOINT
# ============================
@app.get("/health")
def health_check():
    return {"status": "running"}

# ============================
#   RUN FASTAPI SERVER
# ============================
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)

