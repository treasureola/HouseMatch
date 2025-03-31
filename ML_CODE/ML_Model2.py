import json
import numpy as np
from collections import defaultdict
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity, euclidean_distances, manhattan_distances
from scipy.stats import pearsonr
import pandas as pd
from sklearn.model_selection import GridSearchCV

# Load categorized home data
with open("properties.json", "r") as file:
    properties = json.load(file)

# Convert the properties list to a pandas DataFrame
properties_df = pd.DataFrame(properties)

# Load user data
with open("users.json", "r") as file:
    user_data = json.load(file)

# Step 1: Create a dictionary mapping assignedUserID to houses
user_houses = {}
for prop in properties:
    user_id = prop.get("assignedUserID", None)
    if user_id:
        if user_id not in user_houses:
            user_houses[user_id] = []
        user_houses[user_id].append(prop)

# Convert the properties list to a pandas DataFrame
properties_df = pd.DataFrame(properties)

# Load Sentence Transformer model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Convert house data into text descriptions (combine amenities)
house_texts = {
    row['property_id']: " ".join(row['amenities'])
    for _, row in properties_df.iterrows()
}

# Function to calculate similarity metrics
def calculate_similarity(user_vector, house_vector, metric='cosine'):
    if metric == 'cosine':
        return cosine_similarity([user_vector], [house_vector])[0][0]
    elif metric == 'euclidean':
        return -euclidean_distances([user_vector], [house_vector])[0][0]  # Invert to positive
    elif metric == 'manhattan':
        return -manhattan_distances([user_vector], [house_vector])[0][0]  # Invert to positive
    elif metric == 'pearson':
        return pearsonr(user_vector, house_vector)[0]
    elif metric == 'jaccard':
        return jaccard_similarity(user_vector, house_vector)
    elif metric == 'neural':
        return neural_similarity(user_vector, house_vector)
    else:
        raise ValueError("Unknown metric")

# Jaccard Similarity (for sets)
def jaccard_similarity(user_amenities, house_amenities):
    # Convert lists of amenities into sets and compute Jaccard index
    user_set = set(user_amenities)
    house_set = set(house_amenities)
    intersection = len(user_set.intersection(house_set))
    union = len(user_set.union(house_set))
    return intersection / union if union != 0 else 0

# Neural Similarity (using SentenceTransformer)
def neural_similarity(user_vector, house_vector):
    # Use cosine similarity of the embeddings as the neural similarity
    return cosine_similarity([user_vector], [house_vector])[0][0]

# Function to recommend houses based on similarity
def recommend_houses(user_data, properties_df, model, metrics=['cosine'], alpha=0.9):
    recommended_houses = {}

    # Iterate over users
    for user in user_data:
        user_id = user["user_id"]
        user_preferences = user["preferences"]
        user_liked_houses = user["liked_houses"]

        # Get the houses assigned to the user
        assigned_houses = user_houses.get(user_id, [])

        # Convert user preferences into a single text string
        user_pref_text = " ".join([str(value) for value in user_preferences.values()])
        user_vector = model.encode(user_pref_text)

        # Encode the assigned houses descriptions
        house_vectors = {
            house['property_id']: model.encode(" ".join(house['amenities']))
            for house in assigned_houses
        }

        # Encode liked houses
        liked_house_vectors = [
            house_vectors[house_id] for house_id in user_liked_houses if house_id in house_vectors
        ]

        for house_id, house_vector in house_vectors.items():
            if house_id not in user_liked_houses:  # Exclude already liked houses
                # Compute similarity to user preferences for each metric
                for metric in metrics:
                    sim_pref = calculate_similarity(user_vector, house_vector, metric)

                    # Compute similarity to liked houses (average similarity)
                    sim_liked = np.mean([
                        calculate_similarity(liked_vector, house_vector, metric)
                        for liked_vector in liked_house_vectors
                    ]) if liked_house_vectors else 0

                    # Hybrid similarity score: Combine preference similarity & liked house similarity
                    final_score = alpha * sim_pref + (1 - alpha) * sim_liked
                    recommended_houses[(user['email'], house_id, metric)] = (final_score, sim_pref, sim_liked)

    # Sort houses by final hybrid similarity score
    sorted_recommendations = sorted(recommended_houses.items(), key=lambda x: x[1][0], reverse=True)

    return sorted_recommendations

# Get top recommended houses
recommended_houses = recommend_houses(user_data, properties_df, model, metrics=['cosine', 'euclidean', 'manhattan', 'pearson', 'jaccard', 'neural'])

# Function to evaluate the recommendations for each metric
def evaluate_model(recommended_houses, metrics, K=5):
    evaluation_results = {}
    
    for metric in metrics:
        top_k_recommendations = [item for item in recommended_houses if item[0][2] == metric][:K]

        pref_similarities = [sim_pref for _, (_, sim_pref, _) in top_k_recommendations]
        liked_similarities = [sim_liked for _, (_, _, sim_liked) in top_k_recommendations]

        avg_pref_similarity = np.mean(pref_similarities) if pref_similarities else 0
        avg_liked_similarity = np.mean(liked_similarities) if liked_similarities else 0

        evaluation_results[metric] = (avg_pref_similarity, avg_liked_similarity)
    
    return evaluation_results

# Evaluate the model for each metric
evaluation_results = evaluate_model(recommended_houses, metrics=['cosine', 'euclidean', 'manhattan', 'pearson', 'jaccard', 'neural'], K=5)

# Print evaluation results for each metric
print(f"\nEvaluation Results for Top 5 Recommendations:")
for metric, (avg_pref_similarity, avg_liked_similarity) in evaluation_results.items():
    print(f"\n{metric.capitalize()} Similarity:")
    print(f"Average Preference Similarity of Top 5 Recommendations: {avg_pref_similarity:.4f}")
    print(f"Average Liked House Similarity of Top 5 Recommendations: {avg_liked_similarity:.4f}")

# Hyperparameter tuning using GridSearchCV
param_grid = {
    'alpha': [0.1, 0.3, 0.5, 0.7, 0.9],
    'metrics': [['cosine'], ['euclidean'], ['manhattan'], ['pearson'], ['jaccard'], ['neural']]
}

def tune_hyperparameters(user_data, properties_df, model, param_grid):
    best_score = float('-inf')
    best_params = None
    
    for alpha in param_grid['alpha']:
        for metrics in param_grid['metrics']:
            recommended_houses = recommend_houses(user_data, properties_df, model, metrics=metrics, alpha=alpha)
            evaluation_results = evaluate_model(recommended_houses, metrics, K=5)
            avg_pref_similarity, avg_liked_similarity = evaluation_results[metrics[0]]
            score = avg_pref_similarity + avg_liked_similarity
            
            if score > best_score:
                best_score = score
                best_params = {'alpha': alpha, 'metrics': metrics}
    
    return best_params, best_score

best_params, best_score = tune_hyperparameters(user_data, properties_df, model, param_grid)

print(f"\nBest Hyperparameters: {best_params}")
print(f"Best Score: {best_score:.4f}")
