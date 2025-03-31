# import json
# import numpy as np
# import pandas as pd
# from sklearn.metrics.pairwise import cosine_similarity, euclidean_distances, manhattan_distances
# from sklearn.cluster import KMeans, DBSCAN
# from tensorflow.keras.models import Sequential
# from tensorflow.keras.layers import Dense
# from sentence_transformers import SentenceTransformer
# from scipy.stats import pearsonr

# # Load data
# with open("properties.json", "r") as file:
#     properties = json.load(file)

# properties_df = pd.DataFrame(properties)

# with open("users.json", "r") as file:
#     user_data = json.load(file)

# # Load Sentence Transformer model
# model = SentenceTransformer('all-MiniLM-L6-v2')

# # Convert house data into text descriptions (combine amenities)
# house_texts = {
#     row['property_id']: " ".join(row['amenities'])
#     for _, row in properties_df.iterrows()
# }

# # Function to calculate similarity metrics
# def calculate_similarity(user_vector, house_vector, metric='cosine'):
#     if metric == 'cosine':
#         return cosine_similarity([user_vector], [house_vector])[0][0]
#     elif metric == 'euclidean':
#         return -euclidean_distances([user_vector], [house_vector])[0][0]  # Invert the value to make it positive
#     elif metric == 'manhattan':
#         return -manhattan_distances([user_vector], [house_vector])[0][0]  # Invert the value to make it positive
#     elif metric == 'pearson':
#         return pearsonr(user_vector, house_vector)[0]  # Pearson correlation coefficient
#     elif metric == 'jaccard':
#         return jaccard_similarity(user_vector, house_vector)
#     elif metric == 'neural':
#         return cosine_similarity([user_vector], [house_vector])[0][0]  # Neural similarity using embedding similarity
#     else:
#         raise ValueError("Unknown metric")

# # Jaccard Similarity - For comparing sets (amenities or user preferences)
# def jaccard_similarity(user_vector, house_vector):
#     user_set = set(user_vector)
#     house_set = set(house_vector)
#     intersection = len(user_set.intersection(house_set))
#     union = len(user_set.union(house_set))
#     return intersection / union

# # Define Deep Learning Model for Embeddings
# def build_embedding_model(input_dim, output_dim=50):
#     model = Sequential()
#     model.add(Dense(128, input_dim=input_dim, activation='relu'))
#     model.add(Dense(64, activation='relu'))
#     model.add(Dense(output_dim, activation='linear'))  # Output latent space embeddings
#     model.compile(optimizer='adam', loss='mean_squared_error')
#     return model

# # Create deep learning embeddings for users and properties
# def create_embeddings(user_data, properties_df, model, embedding_dim=50):
#     user_embeddings = []
#     property_embeddings = []

#     for user in user_data:
#         user_preferences = user["preferences"]
#         user_pref_text = " ".join([str(value) for value in user_preferences.values()])
#         user_vector = model.encode(user_pref_text)  # Use SentenceTransformer for user vector
#         user_embeddings.append(user_vector)

#     house_vectors = {
#         row['property_id']: model.encode(" ".join(row['amenities']))
#         for _, row in properties_df.iterrows()
#     }

#     return np.array(user_embeddings), np.array(list(house_vectors.values()))

# # Build deep learning model
# embedding_dim = 50
# input_dim = 100  # Adjust as per the input size
# deep_model = build_embedding_model(input_dim=input_dim, output_dim=embedding_dim)

# # Create embeddings using the deep model
# user_embeddings, property_embeddings = create_embeddings(user_data, properties_df, model)

# # Clustering using KMeans
# def cluster_properties_kmeans(property_embeddings, n_clusters=5):
#     kmeans = KMeans(n_clusters=n_clusters, random_state=42)
#     kmeans.fit(property_embeddings)
#     return kmeans.labels_

# # Clustering using DBSCAN
# def cluster_properties_dbscan(property_embeddings, eps=0.5, min_samples=5):
#     dbscan = DBSCAN(eps=eps, min_samples=min_samples)
#     dbscan.fit(property_embeddings)
#     return dbscan.labels_

# # Get KMeans clusters
# kmeans_labels = cluster_properties_kmeans(property_embeddings, n_clusters=5)

# # Get DBSCAN clusters
# dbscan_labels = cluster_properties_dbscan(property_embeddings, eps=0.5, min_samples=5)

# # Recommendation based on clusters and similarity
# def recommend_based_on_clusters(user_embeddings, property_embeddings, kmeans_labels, dbscan_labels, metrics=['cosine'], alpha=0.9):
#     recommended_houses = {}

#     for user_idx, user_embedding in enumerate(user_embeddings):
#         user_cluster = kmeans_labels[user_idx]
#         user_dbscan_cluster = dbscan_labels[user_idx]
        
#         for house_idx, house_vector in enumerate(property_embeddings):
#             house_cluster = kmeans_labels[house_idx]
#             house_dbscan_cluster = dbscan_labels[house_idx]
            
#             # Check if user and house are in the same cluster (for both KMeans and DBSCAN)
#             if user_cluster == house_cluster or user_dbscan_cluster == house_dbscan_cluster:
#                 # Compute similarity to user preferences for each metric
#                 for metric in metrics:
#                     sim_pref = calculate_similarity(user_embedding, house_vector, metric)
#                     final_score = alpha * sim_pref
#                     recommended_houses[(user_idx, house_idx, metric)] = (final_score, sim_pref)

#     # Sort houses by final similarity score
#     sorted_recommendations = sorted(recommended_houses.items(), key=lambda x: x[1][0], reverse=True)
#     return sorted_recommendations

# # Get top recommended houses
# recommended_houses = recommend_based_on_clusters(user_embeddings, property_embeddings, kmeans_labels, dbscan_labels, metrics=['cosine', 'euclidean', 'manhattan', 'pearson', 'jaccard', 'neural'])

# # Function to evaluate the recommendations for each metric
# def evaluate_model(recommended_houses, metrics, K=5):
#     evaluation_results = {}
    
#     for metric in metrics:
#         top_k_recommendations = [item for item in recommended_houses if item[0][2] == metric][:K]

#         pref_similarities = [sim_pref for _, (_, sim_pref) in top_k_recommendations]
#         avg_pref_similarity = np.mean(pref_similarities) if pref_similarities else 0
#         evaluation_results[metric] = avg_pref_similarity
    
#     return evaluation_results

# # Evaluate the model for each metric
# evaluation_results = evaluate_model(recommended_houses, metrics=['cosine', 'euclidean', 'manhattan', 'pearson', 'jaccard', 'neural'], K=5)

# # Print evaluation results
# print(f"\nEvaluation Results for Top 5 Recommendations:")
# for metric, avg_pref_similarity in evaluation_results.items():
#     print(f"\n{metric.capitalize()} Similarity:")
#     print(f"Average Preference Similarity of Top 5 Recommendations: {avg_pref_similarity:.4f}")

# Uses DBScan, KMeans, Metrics, and DeepLearning
import json
import numpy as np
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity, euclidean_distances, manhattan_distances
from sklearn.cluster import KMeans, DBSCAN
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from sentence_transformers import SentenceTransformer
from scipy.stats import pearsonr

# Load datasets
users = pd.read_json("users.json")  # User dataset with preferences and liked houses
properties = pd.read_json("properties.json")  # Property dataset

# Convert DataFrame to list of dictionaries for proper iteration
properties_list = properties.to_dict(orient="records")
users_list = users.to_dict(orient="records")

# Step 1: Create a dictionary mapping assignedUserID to houses
user_houses = {}
for prop in properties_list:
    user_id = prop.get("assignedUserID", None)
    if user_id:
        if user_id not in user_houses:
            user_houses[user_id] = []
        user_houses[user_id].append(prop)

# Load Sentence Transformer model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Convert house data into text descriptions (combine amenities)
house_texts = {
    row['property_id']: " ".join(row['amenities'])
    for _, row in properties.iterrows()
}

# Function to calculate similarity metrics
def calculate_similarity(user_vector, house_vector, metric='cosine'):
    if metric == 'cosine':
        return cosine_similarity([user_vector], [house_vector])[0][0]
    elif metric == 'euclidean':
        return -euclidean_distances([user_vector], [house_vector])[0][0]  # Invert the value to make it positive
    elif metric == 'manhattan':
        return -manhattan_distances([user_vector], [house_vector])[0][0]  # Invert the value to make it positive
    elif metric == 'pearson':
        return pearsonr(user_vector, house_vector)[0]  # Pearson correlation coefficient
    elif metric == 'jaccard':
        return jaccard_similarity(user_vector, house_vector)
    elif metric == 'neural':
        return cosine_similarity([user_vector], [house_vector])[0][0]  # Neural similarity using embedding similarity
    else:
        raise ValueError("Unknown metric")

# Jaccard Similarity - For comparing sets (amenities or user preferences)
def jaccard_similarity(user_vector, house_vector):
    user_set = set(user_vector)
    house_set = set(house_vector)
    intersection = len(user_set.intersection(house_set))
    union = len(user_set.union(house_set))
    return intersection / union

# Define Deep Learning Model for Embeddings
def build_embedding_model(input_dim, output_dim=50):
    model = Sequential()
    model.add(Dense(128, input_dim=input_dim, activation='relu'))
    model.add(Dense(64, activation='relu'))
    model.add(Dense(output_dim, activation='linear'))  # Output latent space embeddings
    model.compile(optimizer='adam', loss='mean_squared_error')
    return model

# Create deep learning embeddings for users and properties
def create_embeddings(user_data, properties_df, model, embedding_dim=50):
    user_embeddings = []
    property_embeddings = []

    for user in user_data:
        user_preferences = user["preferences"]
        user_pref_text = " ".join([str(value) for value in user_preferences.values()])
        user_vector = model.encode(user_pref_text)  # Use SentenceTransformer for user vector
        user_embeddings.append(user_vector)

    house_vectors = {
        row['property_id']: model.encode(" ".join(row['amenities']))
        for _, row in properties_df.iterrows()
    }

    return np.array(user_embeddings), np.array(list(house_vectors.values()))

# Build deep learning model
embedding_dim = 50
input_dim = 100  # Adjust as per the input size
deep_model = build_embedding_model(input_dim=input_dim, output_dim=embedding_dim)

# Create embeddings using the deep model
user_embeddings, property_embeddings = create_embeddings(users_list, properties, model)

# Clustering using KMeans
def cluster_properties_kmeans(property_embeddings, n_clusters=5):
    kmeans = KMeans(n_clusters=n_clusters, random_state=42)
    kmeans.fit(property_embeddings)
    return kmeans.labels_

# Clustering using DBSCAN
def cluster_properties_dbscan(property_embeddings, eps=0.5, min_samples=5):
    dbscan = DBSCAN(eps=eps, min_samples=min_samples)
    dbscan.fit(property_embeddings)
    return dbscan.labels_

# Get KMeans clusters
kmeans_labels = cluster_properties_kmeans(property_embeddings, n_clusters=5)

# Get DBSCAN clusters
dbscan_labels = cluster_properties_dbscan(property_embeddings, eps=0.5, min_samples=5)

# Recommendation based on clusters and similarity
def recommend_based_on_clusters(user_embeddings, property_embeddings, kmeans_labels, dbscan_labels, metrics=['cosine'], alpha=0.9):
    recommended_houses = {}

    for user_idx, user_embedding in enumerate(user_embeddings):
        user_cluster = kmeans_labels[user_idx]
        user_dbscan_cluster = dbscan_labels[user_idx]
        
        for house_idx, house_vector in enumerate(property_embeddings):
            house_cluster = kmeans_labels[house_idx]
            house_dbscan_cluster = dbscan_labels[house_idx]
            
            # Check if user and house are in the same cluster (for both KMeans and DBSCAN)
            if user_cluster == house_cluster or user_dbscan_cluster == house_dbscan_cluster:
                # Compute similarity to user preferences for each metric
                for metric in metrics:
                    sim_pref = calculate_similarity(user_embedding, house_vector, metric)
                    final_score = alpha * sim_pref
                    recommended_houses[(user_idx, house_idx, metric)] = (final_score, sim_pref)

    # Sort houses by final similarity score
    sorted_recommendations = sorted(recommended_houses.items(), key=lambda x: x[1][0], reverse=True)
    return sorted_recommendations

# Function to generate recommendations for each user
def generate_user_recommendations(user_houses, user_embeddings, property_embeddings, kmeans_labels, dbscan_labels, metrics=['cosine'], alpha=0.9):
    user_recommendations = {}
    
    # Print the lengths to debug alignment issue
    print(f"Length of properties_list: {len(properties_list)}")
    print(f"Length of property_embeddings: {len(property_embeddings)}")
    
    # Check if lengths match
    if len(properties_list) != len(property_embeddings):
        raise ValueError("Mismatch between the number of properties and property embeddings.")

    # Create a mapping from property_id to its corresponding embedding
    property_id_to_embedding = {}
    for i, house in enumerate(properties_list):
        property_id = house['property_id']
        if i < len(property_embeddings):  # Ensure index is within bounds
            property_id_to_embedding[property_id] = property_embeddings[i]
        else:
            print(f"Warning: No embedding found for property_id {property_id} at index {i}")

    for user_id, houses in user_houses.items():
        # Find the corresponding user data and embeddings
        user_idx = next((i for i, user in enumerate(users_list) if user['user_id'] == user_id), None)
        if user_idx is None:
            continue
        
        print(f"Generating recommendations for user: {user_id}")
        
        # Get embeddings for the assigned houses for the user
        house_embeddings = []

        for house in houses:
            house_id = house['property_id']
            
            # Fetch the embedding for the house by property_id
            if house_id in property_id_to_embedding:
                house_embeddings.append(property_id_to_embedding[house_id])
            else:
                print(f"Warning: Property with property_id {house_id} does not have a valid embedding.")

        # If no valid house embeddings were found for the user, skip this user
        if not house_embeddings:
            print(f"Warning: No valid embeddings found for user {user_id}")
            continue
        
        # Recommend houses for the current user
        recommended_houses = recommend_based_on_clusters(
            [user_embeddings[user_idx]], house_embeddings, 
            kmeans_labels, dbscan_labels, metrics, alpha
        )
        
        # Store recommendations for the user
        user_recommendations[user_id] = recommended_houses
    
    return user_recommendations

# Get recommendations for all users
user_recommendations = generate_user_recommendations(
    user_houses, user_embeddings, property_embeddings, 
    kmeans_labels, dbscan_labels, metrics=['cosine', 'euclidean', 'manhattan', 'pearson', 'jaccard', 'neural']
)

# Function to evaluate the recommendations for each metric
def evaluate_model(user_recommendations, metrics, K=5):
    evaluation_results = {}
    
    for metric in metrics:
        avg_similarities = []
        
        for user_id, recommendations in user_recommendations.items():
            top_k_recommendations = [item for item in recommendations if item[0][2] == metric][:K]

            pref_similarities = [sim_pref for _, (_, sim_pref) in top_k_recommendations]
            avg_pref_similarity = np.mean(pref_similarities) if pref_similarities else 0
            avg_similarities.append(avg_pref_similarity)
        
        evaluation_results[metric] = np.mean(avg_similarities)  # Average similarity across all users
    
    return evaluation_results

# Evaluate the model for each metric
evaluation_results = evaluate_model(user_recommendations, metrics=['cosine', 'euclidean', 'manhattan', 'pearson', 'jaccard', 'neural'], K=5)

# Print evaluation results
print(f"\nEvaluation Results for Top 5 Recommendations:")
for metric, avg_pref_similarity in evaluation_results.items():
    print(f"\n{metric.capitalize()} Similarity:")
    print(f"Average Preference Similarity of Top 5 Recommendations: {avg_pref_similarity:.4f}")
