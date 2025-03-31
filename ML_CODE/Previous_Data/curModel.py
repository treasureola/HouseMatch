import os
import sklearn
import requests
import json
import pandas as pd
import numpy as np
from sklearn.preprocessing import LabelEncoder
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import OneHotEncoder, MinMaxScaler
from sklearn.preprocessing import StandardScaler
import itertools
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.preprocessing import MultiLabelBinarizer
from sklearn.feature_extraction.text import CountVectorizer

# Bag of words (CountVectorizaer)
# tf-idf
# 3rd party
# put them into categories
# Get the data
# Clustering algorithms 9plot on graph) E.g, k-means
#  Use the clustering to put them into categories
with open("home_data.json", "r") as data:
    home_data = json.load(data) 

user_preferences= [
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
      "Efficient Appliances",
      "On-Site Maintenance",
      "Kitchen with breakfast bar",
      "Granite Quartz Countertops Available",
      "One mile from Gallaudet University",
      "Open Layouts",
      "Private Entrance",
      "Airy 9-foot Ceilings",
      "Fishing Lake",
      "Barn Doors Available",
      "Professional Landscaping",
      "Kitchen with island",
      "Stainless Steel Appliances in Select Homes",
      "Dogs Allowed",
      "Cats Allowed"
]

# Sample user liked houses
Liked_house_id = ['6786270504', '6541999527', "5332041691"]

# Get the data needed
data_needed = {}
for i in range(0,100):
    details = []
    if home_data["data"]["results"][i]["details"] != None:
        details = home_data["data"]["results"][i]["details"][0]["text"]
    # get the data needed from the API
    id = home_data["data"]["results"][i]["property_id"]
    data_needed[id] = details
with open("cur_data.json", "w") as outfile:
    json.dump(data_needed, outfile, indent=3)
    
House_data = data_needed
User_prefrences = user_preferences
house_ids = list(House_data.keys()) #Get house IDs
house_features = list(House_data.values()) #Get house features

# Combine user preferences and house data values. Now using house_features
all_data = [" ".join(User_prefrences)] + [" ".join(house) for house in house_features]

# Create and fit the CountVectorizer
# vectorizer = CountVectorizer()
vectorizer = TfidfVectorizer()
vectorizer.fit(all_data)

# Transform user preferences and house data
user_vector = vectorizer.transform([" ".join(User_prefrences)])
house_vectors = vectorizer.transform([" ".join(house) for house in house_features])

# Calculate cosine similarity
similarity_scores = cosine_similarity(user_vector, house_vectors)[0]

# Create a list of tuples (similarity_score, house_id) using house_ids
ranked_houses = sorted(zip(similarity_scores, house_ids), reverse=True)

# Print the ranked houses
for score, house_id in ranked_houses:
    print(f"House ID: {house_id}, Similarity Score: {score}")

ranked_houses_dict = {house_id: score for score, house_id in ranked_houses}

# Print the dictionary
print("\nRanked Houses Dictionary:")
print(ranked_houses_dict)

# Get indices, handling potential missing IDs
liked_house_indices = [i for i, house_id in enumerate(house_ids) if house_id in Liked_house_id]

if liked_house_indices:
    average_similarity = np.mean(similarity_scores[liked_house_indices]) #Calculates the average similarity score
else:
    average_similarity = 0

# Use NumPy for filtering
recommended_mask = (similarity_scores > average_similarity) & ~np.isin(house_ids, Liked_house_id)
recommended_houses = list(zip(np.array(house_ids)[recommended_mask], similarity_scores[recommended_mask]))

if recommended_houses:
    print("Recommended Houses (above average similarity):")
    for house_id, score in recommended_houses:
        print(f"House ID: {house_id}, Similarity Score: {score}")
else:
    print("No houses found with similarity scores greater than the average similarity of liked houses.")

#Alternative way to recommend top N houses
N = 3 # Number of top recommendations
top_n_recommendations = [(house_id, score) for house_id, score in ranked_houses if house_id not in Liked_house_id][:N]

if top_n_recommendations:
  print(f"\nTop {N} Recommended Houses (excluding liked houses):")
  for score, house_id in top_n_recommendations:
      print(f"House ID: {house_id}, Similarity Score: {score}")
else:
    print("No other houses to recommend.")
    
