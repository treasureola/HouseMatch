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
from sklearn.utils import class_weight
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
from firebase_admin import firestore
from google.cloud.firestore_v1._helpers import DatetimeWithNanoseconds

# =========================
# Read from DB
# =========================
# def json_serial(obj):
#     """JSON serializer for objects not serializable by default"""
#     if isinstance(obj, DatetimeWithNanoseconds):
#         return obj.isoformat()  # Convert to string format (ISO 8601)
#     raise TypeError(f"Type {type(obj)} not serializable")

# cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json")
# firebase_admin.initialize_app(cred)
# db = firestore.client()
# users_ref = db.collection("properties")
# docs = users_ref.stream()
# existing_data = []
# for doc in docs:
#     db_data = doc.to_dict()
#     existing_data.append(db_data)
# with open("db.json", "w") as file:
#     json.dump(existing_data, file, indent=4, default=json_serial)

# =========================
# Configuration
# =========================
# Define file paths and constants
DATA_PATH = "synthetic_data.json"  # Path to property data
# DATA_PATH = "db.json"  # Path to property data
RECOMMENDATION_FILE = "recommendations_1.json"  # Output file for recommendations
GLOBAL_MODEL_PATH = "global_model_1.h5"  # Path to save/load the global model
SCALER_PATH = "scaler_1.npy"  # Path to save/load the scaler parameters

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
def build_model(input_dim):
    input_layer = Input(shape=(input_dim,))  # Input layer
    x = Dense(128, activation="relu", kernel_regularizer=l2(0.01))(input_layer)  # Added L2 regularization
    x = Dropout(0.8)(x)  # Increased dropout rate
    x = Dense(64, activation="relu", kernel_regularizer=l2(0.01))(x)  # Added L2 regularization
    x = Dropout(0.8)(x)  # Increased dropout rate
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
    model.fit(X_train, y_train, epochs=2, batch_size=250, class_weight=class_weight_dict, verbose=1)

    # Evaluate the model
    loss, accuracy = model.evaluate(X_test, y_test, verbose=0)
    log(f"Global Model Accuracy: {accuracy * 100:.2f}%")


    # Save model and scaler
    model.save(GLOBAL_MODEL_PATH)
    np.save(SCALER_PATH, scaler.scale_)

    return model, scaler

# Load the saved scaler from file
def load_scaler():
    scaler = MinMaxScaler()
    scaler.scale_ = np.load(SCALER_PATH)
    return scaler

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
# Recommendation Engine
# =========================
# Generate personalized recommendations for each user
def generate_recommendations(properties_list, user_houses, model, scaler):
    log("Generating personalized recommendations...")
    recommendations = {}

    # Loop through each user to generate predictions
    for user_id, houses in user_houses.items():
        log(f"Processing user {user_id}")
        X_user, y_user = [], []
        for house in houses:
            X_user.append(process_property_interactions(house))
            y_user.append(1 if house.get("favorited", False) else 0)

        # Skip users with too few interactions
        if len(X_user) < 5:
            log(f"User {user_id} skipped due to insufficient data.")
            continue

        X_user = np.array(X_user)
        y_user = np.array(y_user)
        X_user_scaled = scaler.transform(X_user)

        # Split data into training and test sets for the user
        X_train, X_test, y_train, y_test = train_test_split(X_user_scaled, y_user, test_size=0.2, random_state=42)

        # Fine-tune model on user-specific data
        user_model = tf.keras.models.clone_model(model)
        user_model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
        user_model.fit(X_train, y_train, epochs=3, batch_size=8, verbose=0)

        # Evaluate the user model on test data
        loss, accuracy = user_model.evaluate(X_test, y_test, verbose=0)
        log(f"User {user_id} Model Accuracy: {accuracy * 100:.2f}%")

        # Predict on unseen properties
        liked_ids = {h["property_id"] for h in houses if h.get("favorited", False)}
        user_recommendations = []

        for house in properties_list:
            if house["property_id"] in liked_ids:
                continue
            vector = process_property_interactions(house)
            score = float(user_model.predict(scaler.transform([vector]), verbose=0)[0][0])
            user_recommendations.append((house["property_id"], score))

        # Sort and store top 5 recommendations
        user_recommendations.sort(key=lambda x: x[1], reverse=True)
        recommendations[user_id] = {pid: score for pid, score in user_recommendations[:5]}

    return recommendations

# Add recommendations from similar users using collaborative filtering
def add_similar_user_recommendations(user_houses, recommendations):
    log("Enhancing recommendations with similar user behavior using cosine similarity...")

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
        recommendations[user_id] = dict(sorted(recommendations[user_id].items(), key=lambda x: x[1], reverse=True)[:10])

        # Print recommendation list after adding similar-user recommendations
        # log(f"Recommendations for user {user_id} after adding similar-user recommendations: {recommendations[user_id]}")

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
        recommendations[user_id] = dict(sorted(recommendations[user_id].items(), key=lambda x: x[1], reverse=True)[:10])

        # Print recommendation list after adding preference-based recommendations
        # log(f"Recommendations for user {user_id} after adding preference-based recommendations: {recommendations[user_id]}")

    return recommendations
# =========================
# Recommendation Engine (Updated with Weights and Accuracy Calculation)
# =========================
def generate_weighted_recommendations(properties_list, user_houses, model, scaler, behavior_weight=0.6, similar_user_weight=0.2, preference_weight=0.2):
    """
    Generate recommendations based on three sources and merge them with weighted scores.
    behavior_weight, similar_user_weight, and preference_weight control the relative influence of each source.
    This also calculates and logs accuracy for each model.
    """
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
        user_model.fit(X_train, y_train, epochs=3, batch_size=8, verbose=0)
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
        similar_user_recommendations = {}
        similar_user_accuracy = 0  # Placeholder for collaborative filtering accuracy
        for sim_user_id, sim_score in add_similar_user_recommendations(user_houses, {}).get(user_id, {}).items():
            similar_user_recommendations[sim_user_id] = sim_score
            # Simulate accuracy for similar user recommendations
            # This can be replaced by a more sophisticated accuracy calculation based on shared likes or other criteria
            similar_user_accuracy += sim_score

        # Normalize similar user accuracy
        if len(similar_user_recommendations) > 0:
            similar_user_accuracy /= len(similar_user_recommendations)
        similar_user_accuracy = similar_user_accuracy * 100
        log(f"Similar user recommendation accuracy for user {user_id}: {similar_user_accuracy:.2f}%")

        # Preference-based Recommendations (Content-based Filtering)
        preference_recommendations = {}
        preference_accuracy = 0  # Placeholder for preference-based accuracy
        for pref_user_id, pref_score in add_preference_based_recommendations(user_houses, {}).get(user_id, {}).items():
            preference_recommendations[pref_user_id] = pref_score
            # Simulate accuracy for preference-based recommendations
            # Replace with real accuracy computation if applicable (e.g., matching user preferences)
            preference_accuracy += pref_score

        # Normalize preference accuracy
        if len(preference_recommendations) > 0:
            preference_accuracy /= len(preference_recommendations)
        preference_accuracy = preference_accuracy * 100
        log(f"Preference-based recommendation accuracy for user {user_id}: {preference_accuracy:.2f}%")

        # Weighted Combination of Recommendations
        merged_recommendations = {}

        # Behavior-based recommendations
        for prop_id, score in behavior_recommendations:
            merged_recommendations[prop_id] = behavior_weight * score

        # Add similar user recommendations
        for prop_id, score in similar_user_recommendations.items():
            merged_recommendations[prop_id] = merged_recommendations.get(prop_id, 0) + similar_user_weight * score

        # Add preference-based recommendations
        for prop_id, score in preference_recommendations.items():
            merged_recommendations[prop_id] = merged_recommendations.get(prop_id, 0) + preference_weight * score

        # Sort recommendations based on the merged weighted score
        recommendations[user_id] = dict(sorted(merged_recommendations.items(), key=lambda x: x[1], reverse=True)[:10])

    return recommendations

#     return final_recommendations
def calculate_final_accuracy(recommendations, user_houses, top_k=10):
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

# =========================
# Main Execution
# =========================
# Main pipeline for training and generating recommendations
def run_pipeline(retrain_global=False):
    log("Loading data...")
    properties_list = load_property_data(DATA_PATH)
    user_houses = group_user_houses(properties_list)

    # Train global model or load if already trained
    if retrain_global or not os.path.exists(GLOBAL_MODEL_PATH):
        model, scaler = train_global_model(user_houses)
    else:
        log("Loading pre-trained global model...")
        model = tf.keras.models.load_model(GLOBAL_MODEL_PATH)
        scaler = load_scaler()

    # Step 4: Merge all into final recommendations
    # final_recommendations = merge_final_recommendations(behavioral_recs, similar_user_recs, preference_recs)
    recommendations = generate_weighted_recommendations(properties_list, user_houses, model, scaler, behavior_weight=0.6, similar_user_weight=0.2, preference_weight=0.2)
    accuracy_metrics = calculate_final_accuracy(recommendations, user_houses, top_k=10)
    print("Final Recommendation Accuracy Metrics:")
    print(accuracy_metrics)

    # Save final recommendations to file
    with open(RECOMMENDATION_FILE, 'w') as f:
        json.dump(recommendations, f, indent=4)
    log(f"Recommendations saved to {RECOMMENDATION_FILE}")

# Run the pipeline
if __name__ == "__main__":
    run_pipeline(retrain_global=True)  # Set to True to retrain the global model
