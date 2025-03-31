import json
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
import tensorflow as tf
from tensorflow.keras import layers, models
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from tensorflow.keras.optimizers import Adam
from sklearn.metrics import mean_squared_error, mean_absolute_error, roc_auc_score, accuracy_score
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.decomposition import PCA
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
from firebase_admin import firestore
from datetime import datetime
from google.cloud.firestore_v1._helpers import DatetimeWithNanoseconds
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Embedding, Dense, Flatten, Concatenate
from sklearn.preprocessing import LabelEncoder, MinMaxScaler
from sklearn.preprocessing import LabelEncoder, MinMaxScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout

# def json_serial(obj):
#     """JSON serializer for objects not serializable by default"""
#     if isinstance(obj, DatetimeWithNanoseconds):
#         return obj.isoformat()  # Convert to string format (ISO 8601)
#     raise TypeError(f"Type {type(obj)} not serializable")

# cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json")
# firebase_admin.initialize_app(cred)
# db = firestore.client()
# users_ref = db.collection("users")
# docs = users_ref.stream()
# existing_data = []
# for doc in docs:
#     db_data = doc.to_dict()
#     existing_data.append(db_data)
# with open("users.json", "w") as file:
#     json.dump(existing_data, file, indent=4, default=json_serial)


# # Load interactions data
# with open("users.json", "r") as file:
#     user_data = json.load(file)
    
# # Load properties data
# with open("properties.json", "r") as file:
#     property_data = json.load(file)


# ========== Load Sample Data (Replace with Actual Data) ==========
# Load datasets
users = pd.read_json("users.json")  # User dataset with preferences and liked houses
properties = pd.read_json("properties.json")  # Property dataset

# ============================
# Step 1: Data Preprocessing
# ============================
# Encode categorical variables (location)
# Convert city into a numerical format
location_encoder = LabelEncoder()
properties["location"] = location_encoder.fit_transform(properties["city"])

# Encoding the user preferences
property_type_encoder = LabelEncoder()
users["preferences"] = users["preferences"].apply(lambda x: x if isinstance(x, dict) else {})

# Extract all unique amenities
all_amenities = set(a for sublist in properties["amenities"] for a in sublist)

# One-hot encode amenities
# Creates new columns for each amenity (1 = available, 0 = not available).
for amenity in all_amenities:
    properties[amenity] = properties["amenities"].apply(lambda x: 1 if amenity in x else 0)

# Drop unnecessary columns
# Removes the original amenities column after encoding.
properties.drop(["amenities"], axis=1, inplace=True)

# Normalize numerical features
# MinMaxScaler scales values between 0 and 1 for better neural network performance.
scaler = MinMaxScaler()
properties[["price", "square_feet", "bathrooms", "bedrooms"]] = scaler.fit_transform(
    properties[["price", "square_feet", "bathrooms", "bedrooms"]]
)
print("PROPERTIES")
properties

# ============================
# Step 2: Extract User Features
# ============================
# Handles missing preferences by setting default values.
# Encodes categorical features (location, propertyType).
# Normalizes price preferences while preventing division by zero.
def process_user_preferences(user):
    """Convert user preferences into a numerical feature vector."""
    prefs = user["preferences"]

    # Handle missing keys in preferences
    required_keys = ["minPrice", "maxPrice", "bedrooms", "bathrooms", "squareFeet", "location", "propertyType"]
    for key in required_keys:
        if key not in prefs:
            prefs[key] = 0 if key in ["minPrice", "maxPrice", "bathrooms", "bedrooms"] else "Unknown"

    # Encode categorical values
    try:
        location = location_encoder.transform([prefs["location"]])[0]
    except ValueError:
        location = -1  # Assign a special value for unseen locations

    property_type = property_type_encoder.fit_transform([prefs["propertyType"]])[0]

    # Normalize numerical values (Avoid divide by zero error)
    price_range = properties["price"].max() - properties["price"].min()
    price_range = price_range if price_range > 0 else 1e-9  # Prevent divide by zero

    min_price = (prefs["minPrice"] - properties["price"].min()) / price_range
    max_price = (prefs["maxPrice"] - properties["price"].min()) / price_range

    bedrooms = int(prefs["bedrooms"])
    bathrooms = int(prefs["bathrooms"])
    square_feet = int(prefs["squareFeet"].replace("+", "")) if isinstance(prefs["squareFeet"], str) else prefs["squareFeet"]

    return np.array([min_price, max_price, bedrooms, bathrooms, square_feet, location, property_type])


# ============================
# Step 3: Build Deep Learning Model
# ============================
# Input layer: Takes user and property features as input.
# Dense layers: Uses ReLU activation to capture patterns in data.
# Dropout layers: Prevents overfitting.
# Output layer: Uses sigmoid to output a probability (0 = not recommended, 1 = recommended).
# Loss function: binary_crossentropy since it's a binary classification problem.
def build_model(input_dim):
    """Builds a simple neural network for recommendations."""
    model = Sequential([
        Input(shape=(input_dim,)),  # Use Input layer instead of input_shape in Dense
        Dense(64, activation="relu"),
        Dropout(0.2),
        Dense(32, activation="relu"),
        Dropout(0.2),
        Dense(1, activation="sigmoid")  # Output probability of recommendation
    ])
    model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
    return model


# ============================
# Step 4: Train Model
# ============================
# Combines user preferences + house details into a single feature vector.
# Assigns labels (1 if the house was liked, 0 otherwise) for training.
# Trains the neural network for 10 epochs with batch size 8.
# Prepare training data
X_train = []
y_train = []

for _, user in users.iterrows():
    user_vector = process_user_preferences(user)
    
    for _, prop in properties.iterrows():
        property_vector = prop[["price", "square_feet", "bathrooms", "bedrooms", "location"]].values.astype(float)
        interaction_vector = np.concatenate((user_vector, property_vector))
        
        X_train.append(interaction_vector)
        y_train.append(1 if prop["property_id"] in user["liked_houses"] else 0)

X_train = np.array(X_train, dtype=np.float32)  # Ensure numeric dtype
y_train = np.array(y_train, dtype=np.float32)

# Train the model
model = build_model(X_train.shape[1])
model.fit(X_train, y_train, epochs=10, batch_size=8, verbose=1)

# ============================
# Step 5: Accuracy Calculation
# ============================
# Make predictions on the training set
y_train_pred = model.predict(X_train)

# Convert probabilities to binary predictions (0 or 1)
y_train_pred_binary = (y_train_pred > 0.5).astype(int)

# Calculate accuracy
train_accuracy = accuracy_score(y_train, y_train_pred_binary)
print(f"Training Accuracy: {train_accuracy * 100:.2f}%")

# ============================
# Step 6: Recommend Houses
# ============================
# Predicts recommendation scores for each property.
# Sorts houses by score (higher = better match).
# Returns the top 5 recommended houses for the user.
def recommend_houses(user):
    """Predict and recommend top houses for a user with their scores."""
    user_vector = process_user_preferences(user)
    scores = []
    
    for _, prop in properties.iterrows():
        try:
            # Extract features (ensure they exist)
            property_id = prop.get("property_id", "Unknown")  
            city = prop.get("city", "Unknown")  
            price = prop.get("price", 0.0)
            square_feet = prop.get("square_feet", 0)
            bathrooms = prop.get("bathrooms", 0)
            bedrooms = prop.get("bedrooms", 0)
            
            # Prepare input vector for prediction
            property_vector = np.array([price, square_feet, bathrooms, bedrooms, prop["location"]], dtype=float)
            input_vector = np.concatenate((user_vector, property_vector)).reshape(1, -1)
            
            # Get recommendation score
            score = model.predict(input_vector)[0][0]  

            # Store results safely
            scores.append((property_id, city, price, square_feet, bathrooms, bedrooms, score))
        
        except Exception as e:
            print(f"Error processing property {prop}: {e}")

    # Sort houses by predicted score
    scores.sort(key=lambda x: x[-1], reverse=True)
    
    # Print top recommended houses
    print("\nTop Recommended Houses:")
    for house in scores[:5]:
        print(f"House ID: {house[0]}, City: {house[1]}, Price: ${house[2]:,.2f}, "
              f"Size: {house[3]} sqft, Bathrooms: {house[4]}, Bedrooms: {house[5]}, "
              f"Score: {house[6]:.4f}")

    return scores[:5]

# Example: Get recommendations for the first user
recommended_houses = recommend_houses(users.iloc[0])
