import json
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Load Home Data
with open("home_data.json", "r") as data:
    home_data = json.load(data)

# User Preferences (Default)
user_preferences = [
    "Package Receiving",
    "Pool", 
    "Barbecue Area", 
    "Garden", 
    "Master Bath",
    "Large oversized windows", 
    "Shower in the 2nd bathroom", 
    "Berber Carpeting in Select Bedrooms",
    "Pet Park", 
    "High Ceilings", 
    "Open kitchen", 
    "Efficient Appliances"
]

# Obtaining the properties that we need for recommendations
data_needed = {}
for i in range(0, 100):
    details = ""
    if home_data["data"]["results"][i].get("details"):  
        details_list = home_data["data"]["results"][i]["details"]
        if isinstance(details_list, list) and len(details_list) > 0 and isinstance(details_list[0], dict):
            details = details_list[0].get("text", "")
    property_id = home_data["data"]["results"][i]["property_id"]
    data_needed[property_id] = details

house_ids = list(data_needed.keys())
house_features = list(data_needed.values())

def get_recommendations(user_preferences, liked_houses):
    """Generates recommended houses based on user preferences and liked houses."""
    
    # Take into account user preferences with the houses  
    all_data = [" ".join(user_preferences)] + [" ".join(house) for house in house_features]

    # Apply TF-IDF Vectorization
    vectorizer = TfidfVectorizer()
    vectorizer.fit(all_data)
    user_vector = vectorizer.transform([" ".join(user_preferences)])
    house_vectors = vectorizer.transform([" ".join(house) for house in house_features])

    # Compute similarity & filter liked houses
    similarity_scores = cosine_similarity(user_vector, house_vectors)[0]
    ranked_houses = sorted(zip(similarity_scores, house_ids), reverse=True)
    filtered_houses = [house for house in ranked_houses if house[1] not in liked_houses]

    # Return top recommendations
    top_houses = [{"house_id": house_id, "score": float(score)} for score, house_id in filtered_houses]
    return top_houses
