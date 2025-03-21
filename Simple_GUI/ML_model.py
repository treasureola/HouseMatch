import gensim.downloader as api
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, KFold
import xgboost as xgb
from scipy.special import expit  # For sigmoid (logistic) function
import firebase_admin
from firebase_admin import credentials, firestore
import re

# --- 0. Firebase Initialization (Outside any function) ---
# Initialize Firebase Admin SDK (Only once at the beginning)
try:
    firebase_admin.get_app()
except ValueError:  # App doesn't exist
    cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json") 
    firebase_admin.initialize_app(cred)

db = firestore.client()


# --- 1. Load Pre-trained Word Embeddings ---
word_vectors = api.load("glove-wiki-gigaword-100")

# --- 2. Data Retrieval and Preprocessing (from Firestore) ---

def fetch_data_from_firestore():
    """Fetches user interaction and property data from Firestore."""
    users_ref = db.collection("users")
    all_interactions = []
    all_properties = {}  # Store property details by ID

    # Fetch all properties for efficiency
    properties_ref = db.collection("properties")
    for prop_doc in properties_ref.stream():
        property_data = prop_doc.to_dict()
        property_data['id'] = prop_doc.id  # Ensure property ID is included
        all_properties[prop_doc.id] = property_data

    #Fetch Interactions
    for user_doc in users_ref.stream():
        user_id = user_doc.id
        interactions_ref = db.collection("interactions")
        query = interactions_ref.where("user_id", "==", user_id)

        for interaction_doc in query.stream():
            interaction = interaction_doc.to_dict()
            # Fetch the associated property directly from our dictionary
            property_id = interaction["property_id"]
            if property_id in all_properties:
              property_info = all_properties[property_id]
              # Combine interaction and property data
              combined_data = {
                  "user_id": user_id,
                  "property_id": property_id,
                  "bedrooms": property_info.get("bedrooms", 0),  # Use .get() with defaults
                  "bathrooms": property_info.get("bathrooms", 0),
                  "price": property_info.get("price", 0),
                  "sqft": property_info.get("squareFeet", 0),
                  "details": property_info.get("amenities", []), #amenities is the details
                  "rating": interaction.get("rating", 1),  # Default to 1 if not found
                  "favorited": interaction.get("favorited", False),
                  "clicked": interaction.get("clicks", False), #clicks is boolean
                  "total_time": interaction.get("total_time", 0)
              }
              all_interactions.append(combined_data)
            else:
                print(f"Warning: Property {property_id} not found for interaction.")

    return pd.DataFrame(all_interactions)


def clean_amenities(amenities_list):
    """Cleans and standardizes amenity strings."""
    cleaned_amenities = []
    for amenity in amenities_list:
        # Lowercase, remove punctuation (except spaces and hyphens), and strip whitespace
        cleaned = re.sub(r"[^\w\s-]", "", amenity).lower().strip()
        cleaned_amenities.append(cleaned)
    return cleaned_amenities

# --- 3. Feature Engineering ---

def get_detail_embedding(detail_string, word_vectors):
    """Gets the embedding for a single detail string (lowercased)."""
    words = detail_string.lower().split()
    word_embeddings = [word_vectors[word] for word in words if word in word_vectors]
    if not word_embeddings:
        return np.zeros(word_vectors.vector_size)
    return np.mean(word_embeddings, axis=0)


def create_detail_embedding_matrix(detail_vocab, word_vectors):
    """Creates a matrix where each row is the embedding for a detail."""
    embedding_matrix = []
    for detail in detail_vocab:
        embedding_matrix.append(get_detail_embedding(detail, word_vectors))
    return np.array(embedding_matrix)

def create_detail_vocabulary(df):
    all_details = []
    for details_list in df['details']:
        all_details.extend(details_list)  # Already a list, not a dict
    return list(set(all_details))


def get_property_detail_embedding(details_list, detail_to_embedding):
    """Gets the average detail embedding for a *single* property (list of details)."""
    detail_embeddings = []
    for detail in details_list:
        if detail in detail_to_embedding: #check if detail exists
          detail_embeddings.append(detail_to_embedding[detail])
    if not detail_embeddings:
        return np.zeros(next(iter(detail_to_embedding.values())).shape)
    return np.mean(detail_embeddings, axis=0)


def create_features(df, detail_to_embedding):
    """Creates the full feature matrix."""
    numerical_features = df[['bedrooms', 'bathrooms', 'price', 'sqft', 'total_time']].values

    # Handle boolean 'clicked' and 'favorited'
    clicked_features = df['clicked'].astype(int).values.reshape(-1, 1)  # Convert to int and reshape
    favorited_features = df['favorited'].astype(int).values.reshape(-1, 1)

    detail_embeddings = []
    for details_list in df['details']:
        detail_embeddings.append(get_property_detail_embedding(details_list, detail_to_embedding))
    detail_embeddings = np.array(detail_embeddings)
    features = np.concatenate([numerical_features, clicked_features, favorited_features, detail_embeddings], axis=1)

    return features

# --- 4. Model Training ---

def train_model(X_train, y_train, X_val=None, y_val=None):
    """Trains the XGBoost model, with optional validation set."""
    model = xgb.XGBRegressor(objective='reg:logistic',  # Logistic regression for probability
                                eval_metric='aucpr',  # Use AUC-PR for evaluation
                                use_label_encoder=False,
                                random_state=42,
                                n_estimators=250, #increased
                                learning_rate = 0.1
                            )

    if X_val is not None and y_val is not None:
         model.fit(X_train, y_train, eval_set=[(X_val, y_val)], early_stopping_rounds=10, verbose=False) #Early Stopping
    else:
        model.fit(X_train, y_train)
    return model


# --- 5. Recommendation Function ---

def recommend_properties(user_id, properties_df, model, detail_to_embedding):
    """Generates recommendations for a given user."""

    # Filter out properties the user has already interacted with
    user_interactions = df[df['user_id'] == user_id]['property_id'].unique()
    properties_df = properties_df[~properties_df['property_id'].isin(user_interactions)]
    # Check if properties_df is empty after filtering
    if properties_df.empty:
        return []  # Return an empty list if no properties to recommend
    # Feature engineering for the remaining properties
    X_recommend = create_features(properties_df, detail_to_embedding)

    # Predict scores
    scores = model.predict(X_recommend)  # Get raw scores

    # Combine and sort
    recommendations = sorted(zip(properties_df['property_id'], scores), key=lambda x: x[1], reverse=True)
    return recommendations


# --- 6. Main Execution Block ---
if __name__ == "__main__":
    df = fetch_data_from_firestore()

    if df.empty:
        print("No interaction data found.  Exiting.")
        exit()
    #Clean the list of amenities
    df['details'] = df['details'].apply(clean_amenities)
    # Create detail vocabulary and embeddings
    detail_vocab = create_detail_vocabulary(df)
    detail_embedding_matrix = create_detail_embedding_matrix(detail_vocab, word_vectors)
    detail_to_embedding = {detail: embedding for detail, embedding in zip(detail_vocab, detail_embedding_matrix)}

    # --- Cross-Validation ---
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    all_recommendations = [] #store recommendations

    for train_index, val_index in kf.split(df):
      #Split the data based on the fold indices
      df_train = df.iloc[train_index]
      df_val = df.iloc[val_index]

      #Create features and labels
      X_train = create_features(df_train, detail_to_embedding)
      y_train = df_train['rating']
      X_val = create_features(df_val, detail_to_embedding)
      y_val = df_val['rating']

      #Train Model
      model = train_model(X_train, y_train, X_val, y_val) #train with validation set

      #Get all unique user IDs from validation set
      unique_user_ids = df_val['user_id'].unique()

      # Make recommendations for each user in the validation set
      for user_id in unique_user_ids:
        #Get properties *not* interacted with by the user in the *entire* dataset
        user_interactions = df[df['user_id'] == user_id]['property_id'].unique()
        # Filter to get properties available for recommendation (not interacted with)
        recommendation_pool_df = df[~df['property_id'].isin(user_interactions)].drop_duplicates(subset=['property_id'])

        #Generate recommendations
        recommendations = recommend_properties(user_id, recommendation_pool_df, model, detail_to_embedding)

        all_recommendations.extend([(user_id, prop_id, score) for prop_id, score in recommendations])

    # Convert all_recommendations to a DataFrame
    recommendations_df = pd.DataFrame(all_recommendations, columns=['user_id', 'property_id', 'predicted_score'])

    # Calculate average predicted scores for each property across all users
    property_avg_scores = recommendations_df.groupby('property_id')['predicted_score'].mean().reset_index()

    # Sort properties by average score and get the top N
    top_n_properties = property_avg_scores.sort_values(by='predicted_score', ascending=False)

    # Print the top N recommended properties
    print("Top Recommended Properties (Average Scores):")
    print(top_n_properties)