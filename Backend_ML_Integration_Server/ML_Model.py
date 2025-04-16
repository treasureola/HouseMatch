# Import required libraries
import json  # For reading and writing JSON files
import os  # For file path checks
import numpy as np  # For numerical operations
import pandas as pd  # For working with dataframes
from datetime import datetime  # For parsing and converting timestamps
from sklearn.model_selection import train_test_split  # For splitting data
from sklearn.preprocessing import MinMaxScaler  # For feature scaling
from sklearn.metrics.pairwise import cosine_similarity  # For user similarity
import tensorflow as tf  # For deep learning
from tensorflow.keras.layers import Input, Dense, Dropout  # For building model layers
from tensorflow.keras.models import Model  # For defining the model
from scipy.spatial.distance import cdist  # For preference comparison
from tensorflow.keras.regularizers import l2
from tensorflow.keras.regularizers import l1
from sklearn.utils import class_weight
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
from firebase_admin import firestore
from google.cloud.firestore_v1._helpers import DatetimeWithNanoseconds
import uuid
from google.cloud.firestore_v1 import FieldFilter
import joblib
from tensorflow.keras.callbacks import EarlyStopping


# =========================
# Configuration
# =========================
# Define file paths and constants
DATA_PATH = "db.json"  # Path to property data
RECOMMENDATION_FILE = "recommendations.json"  # Output file for recommendations
GLOBAL_MODEL_PATH = "global_model.h5"  # Path to save/load the global model
SCALER_PATH = "scaler.pkl"  # Path to save/load the scaler parameters
PER_USER_DATA_PATH = "user.json"

# =========================
# Read from DB
# =========================
def json_serial(obj):
    """JSON serializer for objects not serializable by default"""
    if isinstance(obj, DatetimeWithNanoseconds):
        return obj.isoformat()  # Convert to string format (ISO 8601)
    raise TypeError(f"Type {type(obj)} not serializable")

# cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json")
# firebase_admin.initialize_app(cred)
# db = firestore.client()

# In ML_Model.py
def refresh_firestore_data_to_json(db, filepath="db.json"):
    users_ref = db.collection("properties")
    docs = users_ref.stream()
    existing_data = []
    for doc in docs:
        db_data = doc.to_dict()
        existing_data.append(db_data)
    with open(filepath, "w") as file:
        json.dump(existing_data, file, indent=4, default=json_serial)

def refresh_firestore_data_to_json_for_user(db, user_id, filepath="user.json"):
    users_ref = db.collection("properties").where(filter=FieldFilter("assignedUserID", "==", str(user_id)))
    docs = users_ref.stream()
    user_properties = []
    for doc in docs:
        db_data = doc.to_dict()
        user_properties.append(db_data)
    with open(filepath, "w") as file:
        json.dump(user_properties, file, indent=4, default=json_serial)


# =========================
# Utilities
# =========================
# Logging utility to print standardized info messages
def log(msg):
    print(f"[INFO] {msg}")

# Convert timestamp string or number to float UNIX timestamp
def convert_timestamp(timestamp):
    if isinstance(timestamp, (int, float)):
        return float(timestamp)
    if isinstance(timestamp, str):
        try:
            return datetime.fromisoformat(timestamp.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return 0  # If invalid format, return 0
    return 0  # If None or unknown type, return 0

# Extract relevant interaction features from a house dict and add static features (price, location, etc.)
def process_property_interactions(house):
    interaction_features = [
        house.get("clicks", 0),
        house.get("viewed", 0),
        house.get("total_time", 0),
        convert_timestamp(house.get("entry_timestamp")),
        house.get("rating", 0),
        1 if house.get("favorited", False) else 0
    ]
    static_features = [
        house.get("price", 0),
        house.get("bedrooms", 0),
        house.get("bathrooms", 0),
        house.get("square_feet", 0),
        hash(house.get("location", "")) % 1000,
        hash(house.get("property_type", "")) % 1000
    ]
    # Ensure that all features are valid numbers
    interaction_features = [x if not np.isnan(x) else 0 for x in interaction_features]
    static_features = [x if not np.isnan(x) else 0 for x in static_features]
    
    return np.array(interaction_features + static_features, dtype=float)


# Build and return a compiled neural network model
# WOrked (0.9, 0.9)
def build_model(input_dim):
    input_layer = Input(shape=(input_dim,))  # Input layer
    x = Dense(128, activation="relu", kernel_regularizer=l2(0.5))(input_layer)  # Added L2 regularization
    x = Dropout(0.4)(x)  # Increased dropout rate
    x = Dense(64, activation="relu", kernel_regularizer=l2(0.9))(x)  # Added L2 regularization
    x = Dropout(0.4)(x)  # Increased dropout rate
    output_layer = Dense(1, activation="sigmoid")(x)  # Output layer for binary prediction
    model = Model(inputs=input_layer, outputs=output_layer)
    model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])  # Compile model
    return model

# =========================
# Data Loading and Prep
# =========================
# Load property data from JSON file and return as list of dicts
def load_property_data(filepath):
    properties = pd.read_json(filepath)
    return properties.to_dict(orient="records")

# # Path to your source and destination files
# file_path = "db.json"
# output_path = PER_USER_DATA_PATH

# # Target user ID
# target_user_id = "6SMA58FmI0Osi0CaD78zDGrpSUd2"

# # Load the JSON and filter
# with open(file_path, "r") as file:
#     data = json.load(file)

# user_properties = [item for item in data if item.get("assignedUserID") == target_user_id]

# # Save to user.json
# with open(output_path, "w") as file:
#     json.dump(user_properties, file, indent=4)

# print(f"✅ Saved {len(user_properties)} properties assigned to user {target_user_id} in '{output_path}'")

    
# # TEST
# def load_property_data_for_user(filepath):
#     properties = pd.read_json(filepath)
#     return properties.to_dict(orient="records")

# Group property interactions by user ID
def group_user_houses(properties_list):
    user_houses = {}
    for prop in properties_list:
        user_id = prop.get("assignedUserID")
        if user_id:
            user_houses.setdefault(user_id, []).append(prop)  # Group by user
    return user_houses

# =========================
# Training Logic
# =========================
# Train the global model using all user data
def train_global_model(user_houses):
    log("Preparing global training data...")
    X_global, y_global = [], []

    # Extract training data and labels from all users
    for houses in user_houses.values():
        for house in houses:
            X_global.append(process_property_interactions(house))
            y_global.append(1 if house.get("favorited", False) else 0)

    # Convert to numpy arrays
    X_global = np.array(X_global)
    y_global = np.array(y_global)

    # Scale the features using MinMaxScaler
    scaler = MinMaxScaler()
    X_scaled = scaler.fit_transform(X_global)

    # Split into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(X_scaled, y_global, test_size=0.2, random_state=42)

    log("Training global model...")
    model = build_model(X_train.shape[1])  # Build model
    # Calculate class weights
    class_weights = class_weight.compute_class_weight('balanced', classes=np.array([0, 1]), y=y_train)

    # Convert to dictionary format
    class_weight_dict = {0: class_weights[0], 1: class_weights[1]}

    # Fit the model with class weights
    
    # model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
    model.fit(X_train, y_train, epochs=50, batch_size=10, class_weight=class_weight_dict, verbose=1)

    # Evaluate the model
    loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
    log(f"Global Model Accuracy: {accuracy * 100:.2f}%")


    # Save model and scaler
    model.save(GLOBAL_MODEL_PATH)
    # np.save(SCALER_PATH, scaler.scale_)
    joblib.dump(scaler, "scaler.pkl")  # Save it

    return model, scaler

# # Load the saved scaler from file
# def load_scaler():
#     scaler = MinMaxScaler()
#     scaler.scale_ = np.load(SCALER_PATH)
#     return scaler
def load_scaler():
    return joblib.load("scaler.pkl")  # Or wherever you saved it

# =========================
# Preference Calculation
# =========================
# Function to compute user preferences based on their liked houses
def compute_user_preferences(user_houses):
    user_preferences = {}
    for user_id, houses in user_houses.items():
        liked_houses = [house for house in houses if house.get("favorited", False)]
        
        if not liked_houses:
            continue  # Skip users with no liked houses

        preference_vectors = []
        for house in liked_houses:
            preference_vectors.append(process_property_interactions(house))
        
        # Ensure there are no NaN values in the preference vectors
        preference_vectors = np.array(preference_vectors)
        if np.any(np.isnan(preference_vectors)):
            print(f"Warning: NaN detected in preference vectors for user {user_id}")
            continue

        user_preferences[user_id] = np.mean(preference_vectors, axis=0)

    return user_preferences
 
# =========================
# Recommendation Engine (Updated with Weights and Accuracy Calculation)
# =========================
# Generate personalized recommendations for each user
# Add recommendations from similar users using collaborative filtering
def add_similar_user_recommendations(user_houses, recommendations):
    log("Adding similar user recommendations...")

    # First, compute the behavior patterns for each user (based on their interactions)
    user_behavior_vectors = {}
    static_feature_length = 6  # Assuming there are 6 static features (price, bedrooms, bathrooms, square_feet, location, property_type)
    
    for user_id, houses in user_houses.items():
        vectors = []
        for house in houses:
            features = process_property_interactions(house)
            vectors.append(features)
        user_behavior_vectors[user_id] = np.mean(vectors, axis=0)  # Averaging interaction features

    user_ids = list(user_behavior_vectors.keys())
    behavior_matrix = np.array([user_behavior_vectors[uid] for uid in user_ids])

    # Static preference comparison part (compare based on price, location, etc.)
    static_preference_vectors = {}
    for user_id, houses in user_houses.items():
        static_preferences = np.mean([process_property_interactions(house)[-static_feature_length:] for house in houses], axis=0)  # Extracting the static features
        static_preference_vectors[user_id] = static_preferences

    static_preference_matrix = np.array([static_preference_vectors[uid] for uid in user_ids])

    for i, user_id in enumerate(user_ids):
        # Compare the current user's behavior to all others using cosine similarity
        user_vector = behavior_matrix[i].reshape(1, -1)
        behavior_similarities = cosine_similarity(user_vector, behavior_matrix)[0]
        
        # Compare the current user's static preferences to all others
        static_user_vector = static_preference_matrix[i].reshape(1, -1)
        static_similarities = cosine_similarity(static_user_vector, static_preference_matrix)[0]

        # Combine both similarity scores (you can use weights if desired)
        combined_similarities = (behavior_similarities + static_similarities) / 2  # Simple average for combining

        # Get the indices of the most similar users (excluding the user themselves)
        similar_indices = np.argsort(combined_similarities)[::-1][1:6]  # Top 5 most similar users

        for idx in similar_indices:
            sim_user_id = user_ids[idx]
            for house in user_houses.get(sim_user_id, []):
                if house.get("favorited", False):  # Only recommend favorited houses
                    score = combined_similarities[idx]  # Combined score for ranking
                    property_id = house["property_id"]
                    if property_id not in recommendations.get(user_id, {}):
                        recommendations.setdefault(user_id, {})[property_id] = score

        recommendations[user_id] = dict(sorted(recommendations[user_id].items(), key=lambda x: x[1], reverse=True)[:100])

    return recommendations

# Add recommendations from similar user preferences (third recommendation source)
def add_preference_based_recommendations(user_houses, recommendations):
    log("Enhancing recommendations with similar preferences using cosine similarity...")

    user_prefs = compute_user_preferences(user_houses)

    for user_id, houses in user_houses.items():
        # Get the user's preference vector (average of their liked houses)
        if user_id not in user_prefs:
            continue
        user_pref = user_prefs[user_id]

        # Calculate cosine similarity to other users' preferences
        preferences = np.array(list(user_prefs.values()))
        cosine_similarities = cosine_similarity([user_pref], preferences)[0]  # Similarity to all other users
        # print(f"Cosine similarities for user {user_id}: {cosine_similarities}")

        # Find similar users (ignore the user themselves at index 0)
        similar_users = np.argsort(cosine_similarities)[::-1][1:6]  # Top 5 similar users
        recommended_properties = set()

        for sim_idx in similar_users:
            similar_user_id = list(user_prefs.keys())[sim_idx]
            for house in user_houses.get(similar_user_id, []):
                if house.get("favorited", False) and house["property_id"] not in recommended_properties:
                    # Use cosine similarity as the score
                    similarity_score = cosine_similarities[sim_idx]  # Similarity score based on cosine similarity
                    recommended_properties.add(house["property_id"])
                    recommendations.setdefault(user_id, {})[house["property_id"]] = similarity_score

        # Sort and trim to top 10 recommendations for each user
        recommendations[user_id] = dict(sorted(recommendations[user_id].items(), key=lambda x: x[1], reverse=True)[:100])

        # Print recommendation list after adding preference-based recommendations
        # log(f"Recommendations for user {user_id} after adding preference-based recommendations: {recommendations[user_id]}")

    return recommendations

def compute_hit_rate_accuracy(recommended_scores: dict, user_liked_ids: set, top_k: int = 10):
    # Sort recommendations by score descending
    top_recs = sorted(recommended_scores.items(), key=lambda x: x[1], reverse=True)[:top_k]
    recommended_ids = {rec[0] for rec in top_recs}
    
    # Intersection with liked property IDs
    hits = recommended_ids & user_liked_ids
    accuracy = len(hits) / top_k if top_k > 0 else 0
    return accuracy * 100  # Convert to %


def generate_weighted_recommendations(properties_list, user_houses, model, scaler, behavior_weight, similar_user_weight, preference_weight):
    log("Generating personalized recommendations with weighted merging...")
    recommendations = {}

    for user_id, houses in user_houses.items():
        log(f"Processing user {user_id}")
        X_user, y_user = [], []
        for house in houses:
            X_user.append(process_property_interactions(house))
            y_user.append(1 if house.get("favorited", False) else 0)

        if len(X_user) < 5:
            log(f"User {user_id} skipped due to insufficient data.")
            continue

        X_user = np.array(X_user)
        y_user = np.array(y_user)
        X_user_scaled = scaler.transform(X_user)

        # Behavior-based Recommendations (Behavior Learning Model)
        X_train, X_test, y_train, y_test = train_test_split(X_user_scaled, y_user, test_size=0.2, random_state=42)
        user_model = tf.keras.models.clone_model(model)
        user_model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
        early_stop = EarlyStopping(monitor='loss', patience=3, restore_best_weights=True)
        user_model.fit(X_train, y_train, epochs=50, batch_size=10, callbacks=[early_stop], verbose=0)
        loss, accuracy = user_model.evaluate(X_test, y_test, verbose=0)
        log(f"User {user_id} Model Accuracy: {accuracy * 100:.2f}%")
        
        # Calculate Behavior Model Accuracy
        behavior_accuracy = accuracy * 100
        log(f"Behavior-based recommendation accuracy for user {user_id}: {behavior_accuracy:.2f}%")
        
        liked_ids = {h["property_id"] for h in houses if h.get("favorited", False)}
        behavior_recommendations = []

        for house in properties_list:
            if house["property_id"] in liked_ids:
                continue
            vector = process_property_interactions(house)
            score = float(user_model.predict(scaler.transform([vector]), verbose=0)[0][0])
            behavior_recommendations.append((house["property_id"], score))

        # Sort by the behavior recommendation score
        behavior_recommendations.sort(key=lambda x: x[1], reverse=True)

        # Similar User Recommendations (Collaborative Filtering)
        # Assuming user_houses is a list of property dicts
        similar_user_recommendations = {}
        preference_recommendations = {}
        # user_houses = [json.loads(house) if isinstance(house, str) else house for house in user_houses]
        # user_idss = {house.get("assignedUserID") for house in user_houses}
        user_idss = len(user_houses)

        if user_idss == 1:
            print(f"All houses are assigned to a single user")
        else:
            actual_liked_ids = {house["property_id"] for house in user_houses[user_id] if house.get("favorited")}

           # ------------------- Similar User Accuracy -------------------
            similar_user_scores = add_similar_user_recommendations(user_houses, {}).get(user_id, {})
            similar_user_accuracy = compute_hit_rate_accuracy(similar_user_scores, actual_liked_ids, top_k=10)
            similar_user_recommendations.update(similar_user_scores)
            log(f"Similar user recommendation accuracy for user {user_id}: {similar_user_accuracy:.2f}%")

            # ------------------- Preference-Based Accuracy -------------------
            preference_scores = add_preference_based_recommendations(user_houses, {}).get(user_id, {})
            preference_accuracy = compute_hit_rate_accuracy(preference_scores, actual_liked_ids, top_k=10)
            preference_recommendations.update(preference_scores)

            log(f"Preference-based recommendation accuracy for user {user_id}: {preference_accuracy:.2f}%")

        # Weighted Combination of Recommendations
        merged_recommendations = {}
        
        # Behavior-based recommendations
        for prop_id, score in behavior_recommendations:
            merged_recommendations[prop_id] = behavior_weight * score
        
        if user_idss == 1:
            print(f"All houses are assigned to a single user")
        else:
            # Add similar user recommendations
            for prop_id, score in similar_user_recommendations.items():
                merged_recommendations[prop_id] = merged_recommendations.get(prop_id, 0) + similar_user_weight * score

            # Add preference-based recommendations
            for prop_id, score in preference_recommendations.items():
                merged_recommendations[prop_id] = merged_recommendations.get(prop_id, 0) + preference_weight * score

        # Sort recommendations based on the merged weighted score
        recommendations[user_id] = dict(sorted(merged_recommendations.items(), key=lambda x: x[1], reverse=True)[:100])
        # recommendations[user_id] = dict(sorted(recommendations[user_id].items(), key=lambda x: x[1], reverse=True)[:100])
        # Store final recommendations in Firestore
        # for user_id, property_scores in recommendations.items():
        #     for property_id, score in property_scores.items():
        #         # Check if this property is already assigned to this user
        #         query = db.collection("properties") \
        #                 .where(filter=FieldFilter("assignedUserID", "==", str(user_id))) \
        #                 .where(filter=FieldFilter("property_id", "==", str(property_id))) \
        #                 .stream()

        #         if not any(query):
        #             # Get the original property
        #             original_query = db.collection("properties") \
        #            .where(filter=FieldFilter("property_id", "==", str(property_id))) \
        #            .limit(1) \
        #            .stream()

        #             found = False
        #             for doc in original_query:
        #                 print(doc)
        #                 found = True
        #                 print(f"Found property: {property_id}")
        #                 original_data = doc.to_dict()
        #                 original_data["assignedUserID"] = user_id
        #                 # original_data["recommendation_score"] = score
        #                 original_data["original_doc_id"] = doc.id

        #                 new_doc_id = str(uuid.uuid4())
        #                 print("Creating new doc with ID:", new_doc_id)
        #                 db.collection("properties").document(new_doc_id).set(original_data)

        #             if not found:
        #                 print(f"No matching property found for user {user_id} and property {property_id}")
        #         else:
        #             print(f"ℹ️ Property {property_id} already assigned to user {user_id}. Skipping.")
        print("\n")
    return recommendations

def load_or_train_model(user_houses):
    if not os.path.exists(GLOBAL_MODEL_PATH):
        return train_global_model(user_houses)
    model = tf.keras.models.load_model(GLOBAL_MODEL_PATH)
    scaler = load_scaler()
    return model, scaler
def generate_recommendations_for_user(user_id, properties, user_houses, model, scaler,
                                      behavior_weight=0.6, similar_user_weight=0.2, preference_weight=0.2):

    all_recs = generate_weighted_recommendations(
        properties,
        user_houses,
        model,
        scaler,
        behavior_weight,
        similar_user_weight,
        preference_weight
    )
    return all_recs

#     return final_recommendations
def calculate_final_accuracy(recommendations, user_houses, top_k=100):
    total_users = 0
    total_hits = 0
    total_precision = 0
    total_recall = 0

    for user_id, recs in recommendations.items():
        recommended_ids = list(recs.keys())[:top_k]
        actual_liked_ids = {house["property_id"] for house in user_houses.get(user_id, []) if house.get("favorited", False)}

        if not actual_liked_ids:
            continue

        total_users += 1
        hits = len(set(recommended_ids) & actual_liked_ids)

        if hits > 0:
            total_hits += 1

        precision = hits / top_k
        recall = hits / len(actual_liked_ids)

        total_precision += precision
        total_recall += recall

    if total_users == 0:
        return {"top_k_hit_rate": 0, "precision": 0, "recall": 0, "f1": 0}

    avg_precision = total_precision / total_users
    avg_recall = total_recall / total_users
    f1 = 2 * (avg_precision * avg_recall) / (avg_precision + avg_recall + 1e-10)

    return {
        "top_k_hit_rate": total_hits / total_users,
        "precision": avg_precision,
        "recall": avg_recall,
        "f1": f1,
    }

# =========================
# Save to DB
# =========================
def save_all_user_property_scores_to_db(recommendations_dict):
    with open(RECOMMENDATION_FILE, 'w') as f:
        json.dump(recommendations_dict, f, indent=4)
    log(f"Recommendations saved to {RECOMMENDATION_FILE}")
    # with open("userRec.json", 'w') as f:
    #     json.dump(recommendations_dict, f, indent=4)
    # log(f"Recommendations saved to userRec.json")
    
    # for user_id, property_scores in recommendations_dict.items():
    #     for property_id, score in property_scores.items():
    #         # Query Firestore for a property with this ID and assigned to this user
    #         query = db.collection("properties") \
    #                   .where(filter=FieldFilter("assignedUserID", "==", str(user_id))) \
    #                   .where(filter=FieldFilter("property_id", "==", str(property_id))) \
    #                   .stream()

    #         updated = False
    #         for doc in query:
    #             doc_ref = db.collection("properties").document(doc.id)
    #             update_data = {
    #                 "recommendation_score": float(score),
    #                 "updated_at": firestore.SERVER_TIMESTAMP
    #             }
    #             doc_ref.set(update_data, merge=True)
    #             print(f"Updated: User {user_id} | Property {property_id} | Score {score:.4f}")
    #             updated = True

    #         if not updated:
    #             print(f"⚠️ Skipped: No matching property found for user {user_id} and property {property_id}")

# =========================
# Main Execution
# =========================                 
# Main pipeline for training and generating recommendations
# Train and return global model + scaler
def retrain_global_model_only():
    log("Retraining only the global model...")
    properties_list = load_property_data(DATA_PATH)
    user_houses = group_user_houses(properties_list)
    model, scaler = train_global_model(user_houses)
    return model, scaler

# Run full recommendation pipeline (optional retrain)
def run_pipeline(retrain_global=False):
    log("Running full pipeline...")
    # refresh_firestore_data_to_json(DATA_PATH)
    properties_list = load_property_data(DATA_PATH)
    # properties_list = load_property_data_for_user(PER_USER_DATA_PATH)
    user_houses = group_user_houses(properties_list)

    if retrain_global or not os.path.exists(GLOBAL_MODEL_PATH):
        model, scaler = train_global_model(user_houses)
    else:
        model = tf.keras.models.load_model(GLOBAL_MODEL_PATH)
        scaler = load_scaler()

    recommendations = generate_weighted_recommendations(
        properties_list,
        user_houses,
        model,
        scaler,
        behavior_weight=0.6,
        similar_user_weight=0.3,
        preference_weight=0.1
    )
    # user_id = "6SMA58FmI0Osi0CaD78zDGrpSUd2",
    # recommendations = generate_recommendations_for_user(
    #         user_id,
    #         properties_list,
    #         user_houses,
    #         model,
    #         scaler,
    #         behavior_weight=0.6,
    #         similar_user_weight=0.2,
    #         preference_weight=0.2
    # )

    save_all_user_property_scores_to_db(recommendations)

    accuracy_metrics = calculate_final_accuracy(recommendations, user_houses, top_k=100)
    print("Final Recommendation Accuracy Metrics:")
    print(accuracy_metrics)

# # Run the pipeline
if __name__ == "__main__":
    # run_pipeline(retrain_global=False)  # Set to True to retrain the global model
    run_pipeline(retrain_global=True)  # Set to True to retrain the global model
