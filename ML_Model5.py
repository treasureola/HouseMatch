# import json
# import numpy as np
# import pandas as pd
# from datetime import datetime
# from sklearn.model_selection import train_test_split
# import tensorflow as tf
# from tensorflow.keras.layers import Input, Dense, Dropout
# from tensorflow.keras.models import Model
# from sklearn.preprocessing import MinMaxScaler
# from sklearn.metrics import accuracy_score

# # Load property dataset
# properties = pd.read_json("new_fake_data.json")

# # Convert DataFrame to list of dictionaries
# properties_list = properties.to_dict(orient="records")

# # Create a dictionary mapping assignedUserID to houses
# user_houses = {}
# for prop in properties_list:
#     user_id = prop.get("assigned_user_id", None)
#     if user_id:
#         if user_id not in user_houses:
#             user_houses[user_id] = []
#         user_houses[user_id].append(prop)
# print(user_houses)

# # Function to convert timestamp to UNIX time (numeric format)
# def convert_timestamp(timestamp):
#     if isinstance(timestamp, (int, float)):  # Already numeric
#         return float(timestamp)
#     if isinstance(timestamp, str):  # Convert from ISO format
#         try:
#             return datetime.fromisoformat(timestamp.replace("Z", "+00:00")).timestamp()
#         except ValueError:
#             return 0  # Default value if conversion fails
#     return 0  # Default for None or unexpected types

# # Function to process property interactions (only interaction-based features)
# def process_property_interactions(house):
#     interaction_data = [
#         house.get("clicks", 0),
#         house.get("viewed", 0),
#         house.get("total_time", 0),
#         convert_timestamp(house.get("entry_timestamp")),  # Convert timestamp
#         house.get("rating", 0)
#     ]
#     return np.array(interaction_data, dtype=float)

# # Function to save recommendations to file
# def save_recommendations_to_file(recommendations, filename="behaviour_result.json"):
#     try:
#         # Check if the file exists
#         try:
#             with open(filename, "r") as file:
#                 data = json.load(file)  # Load existing data if the file exists
#         except FileNotFoundError:
#             data = {}

#         # Append recommendations for each user
#         for user_id, user_recommendations in recommendations.items():
#             if user_id not in data:
#                 data[user_id] = []
#             data[user_id].extend(user_recommendations)

#         # Save updated recommendations back to the file
#         with open(filename, "w") as file:
#             json.dump(data, file, indent=4)

#         print(f"Recommendations successfully saved to {filename}")
#     except Exception as e:
#         print(f"Error saving recommendations to file: {e}")

# # Train a personalized model for each user
# for user_id, houses in user_houses.items():
#     print(f"\nTraining model for User ID: {user_id}")
    
#     X_data = [process_property_interactions(house) for house in houses]
#     X_data = np.array(X_data)

#     # Scale the data
#     scaler = MinMaxScaler()
#     X_data_scaled = scaler.fit_transform(X_data)

#     # Generate artificial labels (temporary labels for learning)
#     y_data = np.random.randint(0, 2, size=(X_data.shape[0],))  # Random 0s and 1s

#     # Split into training/testing sets
#     X_train, X_test, y_train, y_test = train_test_split(X_data_scaled, y_data, test_size=0.2, random_state=42)

#     # Build the recommendation model
#     def build_model(input_dim):
#         input_layer = Input(shape=(input_dim,))
#         x = Dense(128, activation="relu")(input_layer)
#         x = Dropout(0.2)(x)
#         x = Dense(64, activation="relu")(x)
#         x = Dropout(0.2)(x)
#         output_layer = Dense(1, activation="sigmoid")(x)

#         model = Model(inputs=input_layer, outputs=output_layer)
#         model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
#         return model

#     # Train the model
#     model = build_model(X_train.shape[1])
#     model.fit(X_train, y_train, epochs=10, batch_size=8, verbose=0)

#     # Evaluate model
#     y_pred = model.predict(X_test)
#     y_pred = (y_pred > 0.5).astype(int)
#     print(f"Model Accuracy for User {user_id}: {accuracy_score(y_test, y_pred)}")

#     # Generate house recommendations for this user
#     recommendations = []
#     for house in properties_list:
#         house_vector = process_property_interactions(house)
#         house_vector_scaled = scaler.transform([house_vector])
#         score = model.predict(house_vector_scaled)[0][0]
#         recommendations.append((house["property_id"], score))

#     # Sort recommendations by interaction-based score
#     recommendations.sort(key=lambda x: x[1], reverse=True)

#     # Print recommendations
#     print(f"Top 5 House Recommendations for User {user_id}:")
#     for house_id, score in recommendations[:5]:
#         print(f"House ID: {house_id}, Score: {score}")

#     # Evaluation function (based on user interactions only)
#     def evaluate_model(recommended_houses, K=5):
#         top_k_recommendations = recommended_houses[:K]
#         interaction_scores = [score for _, score in top_k_recommendations]
#         avg_interaction_score = np.mean(interaction_scores) if interaction_scores else 0
#         return {"avg_interaction_score": avg_interaction_score}

#     # Evaluate the top recommendations
#     evaluation_results = evaluate_model(recommendations)
#     print(f"Evaluation Results for User {user_id}: {evaluation_results}")

#     # Prepare recommendations for saving
#     user_recommendations = [{
#         "property_id": house_id,
#         "score": score
#     } for house_id, score in recommendations[:5]]

#     # Save recommendations to file
#     save_recommendations_to_file({user_id: user_recommendations})

# 

# import json
# import numpy as np
# import pandas as pd
# from datetime import datetime
# from sklearn.model_selection import train_test_split
# import tensorflow as tf
# from tensorflow.keras.layers import Input, Dense, Dropout
# from tensorflow.keras.models import Model
# from sklearn.preprocessing import MinMaxScaler
# from sklearn.metrics.pairwise import cosine_similarity

# # Load property dataset
# properties = pd.read_json("new_fake_data.json")

# # Convert DataFrame to list of dictionaries
# properties_list = properties.to_dict(orient="records")

# # Create user-to-house interaction mapping
# user_houses = {}
# for prop in properties_list:
#     user_id = prop.get("assigned_user_id", None)
#     if user_id:
#         if user_id not in user_houses:
#             user_houses[user_id] = []
#         user_houses[user_id].append(prop)

# # Function to convert timestamp to UNIX time
# def convert_timestamp(timestamp):
#     if isinstance(timestamp, (int, float)):  
#         return float(timestamp)
#     if isinstance(timestamp, str):  
#         try:
#             return datetime.fromisoformat(timestamp.replace("Z", "+00:00")).timestamp()
#         except ValueError:
#             return 0  
#     return 0  

# # Function to process interaction features
# def process_property_interactions(house):
#     return np.array([
#         house.get("clicks", 0),
#         house.get("viewed", 0),
#         house.get("total_time", 0),
#         convert_timestamp(house.get("entry_timestamp")),
#         house.get("rating", 0),
#         1 if house.get("favorited", False) else 0  
#     ], dtype=float)

# # Prepare training data
# user_ids, house_vectors, labels = [], [], []
# for user_id, houses in user_houses.items():
#     for house in houses:
#         user_ids.append(user_id)
#         house_vectors.append(process_property_interactions(house))
#         labels.append(1 if house.get("favorited", False) else 0)  

# house_vectors = np.array(house_vectors)
# labels = np.array(labels)

# # Scale data
# scaler = MinMaxScaler()
# house_vectors_scaled = scaler.fit_transform(house_vectors)

# # Split into train/test
# X_train, X_test, y_train, y_test = train_test_split(house_vectors_scaled, labels, test_size=0.2, random_state=42)

# # Build the single recommendation model
# def build_model(input_dim):
#     input_layer = Input(shape=(input_dim,))
#     x = Dense(128, activation="relu")(input_layer)
#     x = Dropout(0.2)(x)
#     x = Dense(64, activation="relu")(x)
#     x = Dropout(0.2)(x)
#     output_layer = Dense(1, activation="sigmoid")(x)

#     model = Model(inputs=input_layer, outputs=output_layer)
#     model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
#     return model

# # Train the single model
# model = build_model(X_train.shape[1])
# model.fit(X_train, y_train, epochs=10, batch_size=16, verbose=1)

# # Find user interaction vectors
# user_vectors = {user_id: np.mean([process_property_interactions(h) for h in houses], axis=0)
#                 for user_id, houses in user_houses.items()}
# user_ids = list(user_vectors.keys())
# user_embeddings = np.array(list(user_vectors.values()))

# # Compute similarity between users
# similarity_matrix = cosine_similarity(user_embeddings)

# # Map each user to their similar users
# similar_users = {}
# for i, user_id in enumerate(user_ids):
#     # Get top 5 most similar users (excluding self)
#     similar_users[user_id] = [u[0] for u in sorted(zip(user_ids, similarity_matrix[i]), key=lambda x: x[1], reverse=True)[1:6]]

# # Generate final recommendations for each user
# final_recommendations = {}

# for user_id in user_houses.keys():
#     seen_houses = {house["property_id"] for house in user_houses[user_id] if house.get("favorited", False)}

#     # Get houses liked by similar users but not liked by the current user
#     recommended_houses = set()
#     for similar_user in similar_users.get(user_id, []):
#         for house in user_houses.get(similar_user, []):
#             if house.get("favorited", False) and house["property_id"] not in seen_houses:
#                 recommended_houses.add(house["property_id"])

#     # Save recommendations
#     final_recommendations[user_id] = [{"property_id": house_id} for house_id in recommended_houses]

# # Save recommendations to file
# with open("behavior_result.json", "w") as f:
#     json.dump(final_recommendations, f, indent=4)

# print("Final recommendations saved to behavior_result.json")


import json
import numpy as np
import pandas as pd
from datetime import datetime
from sklearn.model_selection import train_test_split
import tensorflow as tf
from tensorflow.keras.layers import Input, Dense, Dropout
from tensorflow.keras.models import Model
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics.pairwise import cosine_similarity

# Load property dataset
properties = pd.read_json("new_fake_data.json")

# Convert DataFrame to list of dictionaries
properties_list = properties.to_dict(orient="records")

# Create user-to-house interaction mapping
user_houses = {}
for prop in properties_list:
    user_id = prop.get("assigned_user_id", None)
    if user_id:
        if user_id not in user_houses:
            user_houses[user_id] = []
        user_houses[user_id].append(prop)

# Convert timestamp to UNIX time
def convert_timestamp(timestamp):
    if isinstance(timestamp, (int, float)):  
        return float(timestamp)
    if isinstance(timestamp, str):  
        try:
            return datetime.fromisoformat(timestamp.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return 0  
    return 0  

# Extract interaction features
def process_property_interactions(house):
    return np.array([
        house.get("clicks", 0),
        house.get("viewed", 0),
        house.get("total_time", 0),
        convert_timestamp(house.get("entry_timestamp")),
        house.get("rating", 0),
        1 if house.get("favorited", False) else 0  
    ], dtype=float)

# Prepare global dataset
X_global, y_global = [], []
for user_id, houses in user_houses.items():
    for house in houses:
        X_global.append(process_property_interactions(house))
        y_global.append(1 if house.get("favorited", False) else 0)

X_global = np.array(X_global)
y_global = np.array(y_global)

# Scale data
scaler = MinMaxScaler()
X_global_scaled = scaler.fit_transform(X_global)

# Split global data
X_train, X_test, y_train, y_test = train_test_split(X_global_scaled, y_global, test_size=0.2, random_state=42)

# Build the recommendation model
def build_model(input_dim):
    input_layer = Input(shape=(input_dim,))
    x = Dense(128, activation="relu")(input_layer)
    x = Dropout(0.2)(x)
    x = Dense(64, activation="relu")(x)
    x = Dropout(0.2)(x)
    output_layer = Dense(1, activation="sigmoid")(x)

    model = Model(inputs=input_layer, outputs=output_layer)
    model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
    return model

# Train the global model
global_model = build_model(X_train.shape[1])
global_model.fit(X_train, y_train, epochs=10, batch_size=16, verbose=1)

# Evaluate the model on the test set
loss, accuracy = global_model.evaluate(X_test, y_test, verbose=1)
print(f"Global Model Accuracy: {accuracy * 100:.2f}%")

# Fine-tune for each user and generate recommendations
recommendations = {}

for user_id, houses in user_houses.items():
    X_user, y_user = [], []
    
    for house in houses:
        X_user.append(process_property_interactions(house))
        y_user.append(1 if house.get("favorited", False) else 0)

    if len(X_user) < 5:  
        continue

    X_user = np.array(X_user)
    y_user = np.array(y_user)

    X_user_scaled = scaler.transform(X_user)

    # Fine-tune the model for this user
    user_model = tf.keras.models.clone_model(global_model)
    user_model.compile(optimizer="adam", loss="binary_crossentropy", metrics=["accuracy"])
    user_model.fit(X_user_scaled, y_user, epochs=3, batch_size=8, verbose=0)

    # Generate recommendations
    user_recommendations = []
    liked_house_ids = {house["property_id"] for house in houses if house.get("favorited", False)}

    for house in properties_list:
        if house["property_id"] in liked_house_ids:
            continue  

        house_vector = process_property_interactions(house)
        house_vector_scaled = scaler.transform([house_vector])
        score = float(user_model.predict(house_vector_scaled)[0][0])  
        user_recommendations.append((house["property_id"], score))
    
    # Sort by score
    user_recommendations.sort(key=lambda x: x[1], reverse=True)

    # Store recommendations (Initial top 5)
    recommendations[user_id] = {house_id: score for house_id, score in user_recommendations[:5]}

# Find similar users
user_vectors = {user_id: np.mean([process_property_interactions(h) for h in houses], axis=0)
                for user_id, houses in user_houses.items()}
user_ids = list(user_vectors.keys())
user_embeddings = np.array(list(user_vectors.values()))

# Compute user similarity
similarity_matrix = cosine_similarity(user_embeddings)

# Identify similar users
similar_users = {}
for i, user_id in enumerate(user_ids):
    similar_users[user_id] = sorted(zip(user_ids, similarity_matrix[i]), key=lambda x: x[1], reverse=True)[1:6]

# Add similar users' liked houses to the recommendation list
for user_id, similar_list in similar_users.items():
    liked_houses = {house["property_id"] for house in user_houses.get(user_id, []) if house.get("favorited", False)}
    additional_recommendations = []

    for similar_user, _ in similar_list:
        for house in user_houses.get(similar_user, []):
            if house.get("favorited", False) and house["property_id"] not in liked_houses:
                additional_recommendations.append(house["property_id"])

    # Assign a fixed score (0.5) to similar user recommendations
    for house_id in additional_recommendations:
        if house_id not in recommendations[user_id]:
            recommendations[user_id][house_id] = 0.5  

    # Sort all recommendations for the user
    recommendations[user_id] = sorted(recommendations[user_id].items(), key=lambda x: x[1], reverse=True)[:10]

# Convert recommendations to JSON format
final_recommendations = {
    user_id: [{"property_id": house_id, "score": score} for house_id, score in recs]
    for user_id, recs in recommendations.items()
}

# Save recommendations
with open("merged_recommendations1.json", "w") as f:
    json.dump(final_recommendations, f, indent=4)

print("Recommendations saved to merged_recommendations1.json")
