import json  
import numpy as np  
from collections import defaultdict 
from sentence_transformers import SentenceTransformer  
from sklearn.metrics.pairwise import cosine_similarity  
import pandas as pd

# __________INTEGRATION 2 _________ (LOAD DATA FROM DB)
# Load categorized home data
with open("categorized_Data.json", "r") as file:
    home_data = json.load(file)

# User preferences
user_preferences = {
    "Security": ["Package Receiving", "Gate", "Secured Entry"],
    "Amenities": ["Pool", "Barbecue Area", "Kitchen with island", "Fitness Center", "1 Block to Metro Red Line"],
    "Pet_Friendly": ["Cats Allowed", "Dogs Allowed", "Pet Washing Station"]
}

# Houses the user has liked
user_liked_house = ["9966966857", "9091701101", "9342233213", "6786270504"]

# Load Sentence Transformer model
model = SentenceTransformer('all-MiniLM-L6-v2')

# Convert house data into text descriptions
house_texts = {
    house_id: " ".join(sum(categories.values(), []))
    for house_id, categories in home_data.items()
}

# Convert user preferences into a single text string
user_pref_text = " ".join(sum(user_preferences.values(), []))

# Encode user preferences
user_vector = model.encode(user_pref_text)

# Encode house descriptions
house_vectors = {
    house_id: model.encode(house_text) for house_id, house_text in house_texts.items()
}

# Encode liked houses
liked_house_vectors = [
    house_vectors[house_id] for house_id in user_liked_house if house_id in house_vectors
]

# Function to recommend houses based on **both preference similarity & liked house similarity**
def recommend_houses(user_vector, house_vectors, liked_house_vectors, user_liked_house, alpha=0.9):
    recommended_houses = {}

    for house_id, house_vector in house_vectors.items():
        if house_id not in user_liked_house:  # Exclude already liked houses
            # Compute similarity to user preferences
            sim_pref = cosine_similarity([user_vector], [house_vector])[0][0]

            # Compute similarity to liked houses (average similarity)
            sim_liked = np.mean([
                cosine_similarity([liked_vector], [house_vector])[0][0]
                for liked_vector in liked_house_vectors
            ]) if liked_house_vectors else 0

            # Hybrid similarity score: Combine preference similarity & liked house similarity
            final_score = alpha * sim_pref + (1 - alpha) * sim_liked
            recommended_houses[house_id] = (final_score, sim_pref, sim_liked)

    # Sort houses by final hybrid similarity score
    sorted_recommendations = sorted(recommended_houses.items(), key=lambda x: x[1][0], reverse=True)

    # Debugging: Print top 10 recommended houses
    print("\nTop 10 Recommended Houses:")
    for house_id, (final_score, sim_pref, sim_liked) in sorted_recommendations[:10]:
        print(f"House ID: {house_id}, Final Score: {final_score:.4f}, Pref Sim: {sim_pref:.4f}, Liked Sim: {sim_liked:.4f}")

    return sorted_recommendations

# Get top recommended houses
recommended_houses = recommend_houses(user_vector, house_vectors, liked_house_vectors, user_liked_house)

# Function to evaluate the recommendations
def evaluate_model(recommended_houses, K=5):
    """
    Evaluates recommendations based on:
    - How similar the top-K recommended houses are to the user preferences.
    - How similar the top-K recommended houses are to the liked houses.
    """
    top_k_recommendations = recommended_houses[:K]

    # Extract preference similarities and liked house similarities
    pref_similarities = [sim_pref for _, (_, sim_pref, _) in top_k_recommendations]
    liked_similarities = [sim_liked for _, (_, _, sim_liked) in top_k_recommendations]

    # Compute average similarity scores
    avg_pref_similarity = np.mean(pref_similarities) if pref_similarities else 0
    avg_liked_similarity = np.mean(liked_similarities) if liked_similarities else 0

    return avg_pref_similarity, avg_liked_similarity

# Evaluate the model
avg_pref_similarity, avg_liked_similarity = evaluate_model(recommended_houses, K=5)

# Print results
print(f"\nEvaluation Results:")
print(f"Average Preference Similarity of Top 5 Recommendations: {avg_pref_similarity:.4f}")
print(f"Average Liked House Similarity of Top 5 Recommendations: {avg_liked_similarity:.4f}")
# __________INTEGRATION 3 _________ (LOAD DATA FROM DB)
# SAVE RECOMMENDED HOUSES TO DB
