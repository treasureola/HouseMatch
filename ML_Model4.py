import json
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.models import Sequential  # For the Sequential model
from tensorflow.keras.layers import Input, Dense, Dropout
from tensorflow.keras.models import Model
from sklearn.preprocessing import StandardScaler, LabelEncoder, MinMaxScaler
from sklearn.metrics import mean_squared_error, mean_absolute_error, accuracy_score, roc_auc_score  # For evaluating metrics

# Uses Deep Learning
# Load datasets
users = pd.read_json("users.json")  # User dataset with preferences and liked houses
properties = pd.read_json("properties.json")  # Property dataset

# Convert DataFrame to list of dictionaries for proper iteration
properties_list = properties.to_dict(orient="records")
users_list = users.to_dict(orient="records")

# Create a dictionary mapping assignedUserID to houses
user_houses = {}
for prop in properties_list:
    user_id = prop.get("assignedUserID", None)
    if user_id:
        if user_id not in user_houses:
            user_houses[user_id] = []
        user_houses[user_id].append(prop)

# Initialize LabelEncoder for categorical data
location_encoder = LabelEncoder()

# Fit the encoder on all unique location values
locations = pd.Series([user['preferences']['location'] for user in users_list]).unique()
location_encoder.fit(locations)

# Function to process user preferences and encode categorical data
def process_user_preferences(user, location_encoder):
    preferences = user["preferences"]
    location = preferences["location"]
    
    # Ensure proper encoding of location
    location_encoded = location_encoder.transform([location])[0] if location in location_encoder.classes_ else -1

    # Return the user vector with encoded location and other features
    return np.array([
        float(preferences["maxPrice"]),
        float(preferences["bedrooms"]),
        float(preferences["squareFeet"].replace("+", "")),  # Clean up "+" from squareFeet
        float(preferences["bathrooms"]),
        location_encoded
    ], dtype=float)
    
# Function to process property interactions
def process_property_interactions(house):
    # Extract interaction data for the house
    interaction_data = [
        house.get("clicks", 0),
        house.get("viewed", 0),
        house.get("total_time", 0),
        house.get("entry_timestamp", 0), 
        house.get("rating", 0)
    ]
    
    # Convert non-numeric values to NaN and handle them
    interaction_data = [
        float(value) if isinstance(value, (int, float)) else 0 for value in interaction_data
    ]
    
    # Check for NaN values in the interaction data
    if any(np.isnan(interaction_data)):
        print(f"Warning: NaN values found in interaction data for property ID {house['property_id']}")
        interaction_data = [0] * len(interaction_data)  # Replace with zero if NaN

    return np.array(interaction_data, dtype=float)


# Function to check for NaN values in the data
def check_for_nan_in_data(X_train, y_train):
    if np.any(np.isnan(X_train)):
        print("Warning: NaN values found in feature data.")
        print(X_train[np.isnan(X_train)])
    if np.any(np.isnan(y_train)):
        print("Warning: NaN values found in target data.")
        print(y_train[np.isnan(y_train)])

# Prepare the data for each user using user_houses
def prepare_data_for_user(user, user_houses, location_encoder):
    X_data = []
    y_data = []

    # Process the user data and their liked houses
    user_vector = process_user_preferences(user, location_encoder)
    liked_houses = user.get("liked_houses", [])

    # Process the houses liked by the user
    for house_id in liked_houses:
        # Get the house information from user_houses using the user_id
        house = next((prop for prop in user_houses.get(user["user_id"], []) if prop["property_id"] == house_id), None)
        if house:
            house_vector = process_property_interactions(house)
            X_data.append(np.concatenate([user_vector, house_vector]))  # Combine user and house features
            y_data.append(1)  # Label 1 for liked houses

    # Process houses not liked by the user
    for house in user_houses.get(user["user_id"], []):  # Use user_houses to get assigned houses
        if house["property_id"] not in liked_houses:
            house_vector = process_property_interactions(house)
            X_data.append(np.concatenate([user_vector, house_vector]))  # Combine user and house features
            y_data.append(0)  # Label 0 for non-liked houses

    return np.array(X_data), np.array(y_data)

# Function to build the model
def build_model(input_dim):
    """Build a simple neural network for recommendations."""
    input_layer = Input(shape=(input_dim,))  # Define the input layer with the appropriate shape
    
    x = Dense(128, activation="relu")(input_layer)
    x = Dropout(0.2)(x)
    x = Dense(64, activation="relu")(x)
    x = Dropout(0.2)(x)
    output_layer = Dense(1, activation="sigmoid")(x)  # Output: 1 (like) or 0 (dislike)
    
    model = Model(inputs=input_layer, outputs=output_layer)  # Create the model using the Input and output layers
    model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
    return model

# Iterate through each user and train a model
for user in users_list:
    print(f"Training model for user: {user['email']}")
    
    # Prepare the data for the current user using user_houses
    X_data, y_data = prepare_data_for_user(user, user_houses, location_encoder)
    
    # Check for NaN values in the data
    check_for_nan_in_data(X_data, y_data)
    
    # Scale the data (only for numerical features)
    scaler = MinMaxScaler()
    X_data_scaled = scaler.fit_transform(X_data)
    
    # Split data into training and testing sets
    X_train, X_test, y_train, y_test = train_test_split(X_data_scaled, y_data, test_size=0.2, random_state=42)
    
    # Build and train the model for the current user
    model = build_model(X_train.shape[1])
    model.fit(X_train, y_train, epochs=10, batch_size=8, verbose=1)
    
    # Evaluate the model
    y_pred = model.predict(X_test)
    y_pred = (y_pred > 0.5).astype(int)  # Convert probabilities to binary predictions

    # Print evaluation metrics
    print(f"Accuracy for user {user['email']}: {accuracy_score(y_test, y_pred)}")
    print(f"Mean Squared Error for user {user['email']}: {mean_squared_error(y_test, y_pred)}")
    print(f"Mean Absolute Error for user {user['email']}: {mean_absolute_error(y_test, y_pred)}")
    print(f"ROC AUC Score for user {user['email']}: {roc_auc_score(y_test, y_pred)}")

    # Making recommendations
    recommendations = []
    for i, house in enumerate(properties_list):
        property_vector = process_property_interactions(house)

        # Generate recommendation score for each house
        user_vector = process_user_preferences(user, location_encoder)
        user_house_features = np.concatenate([user_vector, property_vector])
        user_house_features_scaled = scaler.transform([user_house_features])  # Scale the features
        score = model.predict(user_house_features_scaled)[0][0]
        recommendations.append((house["property_id"], score))

    # Sort recommendations by score
    recommendations.sort(key=lambda x: x[1], reverse=True)

    # Print the recommendations
    print(f"Recommendations for user {user['email']}:")
    for house_id, score in recommendations[:5]:
        print(f"House ID: {house_id}, Recommendation Score: {score}")