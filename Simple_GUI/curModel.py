#
//  curModel.py
//  Simple_GUI
//
//  Created by Sylmira Kailey on 2/28/25.
//


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
import firebase_admin
from firebase_admin import credentials, auth, firestore


cred = credentials.Certificate('housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json')
firebase_admin.initialize_app(cred)

db = firestore.client()  # Firestore client

#Get user ID from Firebase Authentication
def get_user_id(id_token):
    try:
        decoded_token = auth.verify_id_token(id_token)
        uid = decoded_token['uid']
        return uid
    except Exception as e:
        print(f"Error verifying token: {e}")
        return None
        
#Fetch user's unviewed properties
def fetch_unviewed_properties(user_id):
    properties_ref = db.collection("properties")
    query = properties_ref.where("assignedUserID", "==", user_id).where("viewed", "==", False)
    properties = query.stream()

    house_data = {}
    for prop in properties:
        prop_data = prop.to_dict()
        house_data[prop_data["property_id"]] = prop_data.get("amenities", [])

    return house_data
        
#Fetch user implicit preferences from Firestore
def fetch_implicit_preferences(user_id):
    user_ref = db.collection("users").document(user_id)
    user_data = user_ref.get().to_dict()

    return user_data.get("implicit_preferences", [])
    
#Store updated implicit preferences
def update_user_preferences(user_id, new_amenities):
    user_ref = db.collection("users").document(user_id)
    
    # Fetch existing preferences
    existing_prefs = fetch_user_implicit_preferences(user_id)
    
    # Merge and remove duplicates
    updated_prefs = list(set(existing_prefs + new_amenities))
    
    # Store in Firestore
    user_ref.update({"implicit_preferences": updated_prefs})
    print(f"Updated user preferences for {user_id}: {updated_prefs}")
    
    
# Generate personalized recommendations
def generate_recommendations(id_token):
    user_id = get_user_id(id_token)
    if not user_id:
        print("Unable to get user ID")
        return
    
    # Fetch user's implicit preferences
    user_implicit_preferences = fetch_user_implicit_preferences(user_id)
    
    if not user_implicit_preferences:
        print("No implicit preferences found, skipping recommendations.")
        return

    print(f"Generating recommendations for {user_id}...")

    # Fetch property data from Firestore
    house_data = fetch_unviewed_properties(user_id)
    house_ids = list(house_data.keys())
    house_features = list(house_data.values())
    if not house_features:
        print("No unviewed properties found.")
        return

    # Combine user preferences and house features
    all_data = [" ".join(user_implicit_preferences)] + [" ".join(house) for house in house_features]

    # Create and fit the TF-IDF Vectorizer
    vectorizer = TfidfVectorizer()
    vectorizer.fit(all_data)

    # Transform data into vectors
    user_vector = vectorizer.transform([" ".join(user_implicit_preferences)])
    house_vectors = vectorizer.transform([" ".join(house) for house in house_features])

    # Compute cosine similarity
    similarity_scores = cosine_similarity(user_vector, house_vectors)[0]

    # Rank houses by similarity
    ranked_houses = sorted(zip(similarity_scores, house_ids), reverse=True)
#    ranked_houses_dict = {house_id: score for score, house_id in ranked_houses}

    # Store recommendation scores for properties **only** assigned to the user
    properties_ref = db.collection("properties")

    for score, house_id in ranked_houses:
        property_ref = properties_ref.document(house_id)
        
        # Fetch property data to confirm it belongs to the user
        property_data = property_ref.get().to_dict()
        if property_data and property_data.get("assignedUserID") == user_id:
            property_ref.update({"recommendation_score": score})
            print(f"Updated property {house_id} with recommendation score: {score}")

    print(f"Recommendations stored for user {user_id}")

    
    
## Function to update user preferences when they swipe right
#def process_swipe(user_id, property_id, swiped_right):
#    properties_ref = db.collection("properties").document(property_id)
#    property_data = properties_ref.get().to_dict()
#
#    if not property_data:
#        print(f"Property {property_id} not found in Firestore.")
#        return
#
#    amenities = property_data.get("amenities", [])
#
#    if swiped_right:
#        print(f"User {user_id} liked {property_id}, updating preferences...")
#        update_user_preferences(user_id, amenities)
#    else:
#        print(f"User {user_id} disliked {property_id}, no update needed.")

# Test
id_token = "USER_ID_TOKEN_HERE"  # Replace with actual token from frontend
generate_recommendations(id_token)


#Entry Point (Run via Swift)
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("No ID token provided.")
        sys.exit(1)

    id_token = sys.argv[1]  # Read ID token passed from Swift
    generate_recommendations(id_token)
#
#
## Bag of words (CountVectorizaer)
## tf-idf
## 3rd party
## put them into categories
## Get the data
## Clustering algorithms 9plot on graph) E.g, k-means
##  Use the clustering to put them into categories
#with open("home_data.json", "r") as data:
#    home_data = json.load(data) 
#
#user_preferences= [
#      "Package Receiving",
#      "Pool",
#      "Barbecue Area",
#      "Garden",
#      "Master Bath",
#      "Large oversized windows",
#      "Shower in the 2nd bathroom",
#      "Berber Carpeting in Select Bedrooms",
#      "Pet Park",
#      "High Ceilings",
#      "Open kitchen",
#      "Efficient Appliances",
#      "On-Site Maintenance",
#      "Kitchen with breakfast bar",
#      "Granite Quartz Countertops Available",
#      "One mile from Gallaudet University",
#      "Open Layouts",
#      "Private Entrance",
#      "Airy 9-foot Ceilings",
#      "Fishing Lake",
#      "Barn Doors Available",
#      "Professional Landscaping",
#      "Kitchen with island",
#      "Stainless Steel Appliances in Select Homes",
#      "Dogs Allowed",
#      "Cats Allowed"
#]
#
## Sample user liked houses
#Liked_house_id = ['6786270504', '6541999527', "5332041691"]
#
## Get the data needed
#data_needed = {}
#for i in range(0,100):
#    details = []
#    if home_data["data"]["results"][i]["details"] != None:
#        details = home_data["data"]["results"][i]["details"][0]["text"]
#    # get the data needed from the API
#    id = home_data["data"]["results"][i]["property_id"]
#    data_needed[id] = details
#with open("cur_data.json", "w") as outfile:
#    json.dump(data_needed, outfile, indent=3)
#    
#House_data = data_needed
#User_prefrences = user_preferences
#house_ids = list(House_data.keys()) #Get house IDs
#house_features = list(House_data.values()) #Get house features
#
## Combine user preferences and house data values. Now using house_features
#all_data = [" ".join(User_prefrences)] + [" ".join(house) for house in house_features]
#
## Create and fit the CountVectorizer
## vectorizer = CountVectorizer()
#vectorizer = TfidfVectorizer()
#vectorizer.fit(all_data)
#
## Transform user preferences and house data
#user_vector = vectorizer.transform([" ".join(User_prefrences)])
#house_vectors = vectorizer.transform([" ".join(house) for house in house_features])
#
## Calculate cosine similarity
#similarity_scores = cosine_similarity(user_vector, house_vectors)[0]
#
## Create a list of tuples (similarity_score, house_id) using house_ids
#ranked_houses = sorted(zip(similarity_scores, house_ids), reverse=True)
#
## Print the ranked houses
#for score, house_id in ranked_houses:
#    print(f"House ID: {house_id}, Similarity Score: {score}")
#
#ranked_houses_dict = {house_id: score for score, house_id in ranked_houses}
#
## Print the dictionary
#print("\nRanked Houses Dictionary:")
#print(ranked_houses_dict)
#
## Get indices, handling potential missing IDs
#liked_house_indices = [i for i, house_id in enumerate(house_ids) if house_id in Liked_house_id]
#
#if liked_house_indices:
#    average_similarity = np.mean(similarity_scores[liked_house_indices]) #Calculates the average similarity score
#else:
#    average_similarity = 0
#
## Use NumPy for filtering
#recommended_mask = (similarity_scores > average_similarity) & ~np.isin(house_ids, Liked_house_id)
#recommended_houses = list(zip(np.array(house_ids)[recommended_mask], similarity_scores[recommended_mask]))
#
#if recommended_houses:
#    print("Recommended Houses (above average similarity):")
#    for house_id, score in recommended_houses:
#        print(f"House ID: {house_id}, Similarity Score: {score}")
#else:
#    print("No houses found with similarity scores greater than the average similarity of liked houses.")
#
##Alternative way to recommend top N houses
#N = 3 # Number of top recommendations
#top_n_recommendations = [(house_id, score) for house_id, score in ranked_houses if house_id not in Liked_house_id][:N]
#
#if top_n_recommendations:
#  print(f"\nTop {N} Recommended Houses (excluding liked houses):")
#  for score, house_id in top_n_recommendations:
#      print(f"House ID: {house_id}, Similarity Score: {score}")
#else:
#    print("No other houses to recommend.")
#    
