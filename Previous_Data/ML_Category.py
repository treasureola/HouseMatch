import json  
import numpy as np  
from collections import defaultdict 
from sentence_transformers import SentenceTransformer  
from sklearn.metrics.pairwise import cosine_similarity  
import pandas as pd  
import firebase_admin
from firebase_admin import credentials
from firebase_admin import db
from firebase_admin import firestore

# __________INTEGRATION 1 _________ (LOAD DATA FROM DB)
# Load categorized home dattails

cred = credentials.Certificate("housematch-official-firebase-adminsdk-fbsvc-d0bd0d54c3.json")
firebase_admin.initialize_app(cred)
db = firestore.client()
doc_ref = db.collection("properties")
docs = doc_ref.stream()
existing_data = []
for doc in docs:
    db_data = doc.to_dict()
    existing_data.append(db_data)

with open("db.json", "w") as file:
    json.dump(existing_data, file, indent=4)

# Convert to dictionary with listing_id as key and amenities as value
# listings_dict = {doc.id: doc.to_dict().get("amenities", []) for doc in docs}
listings_dict = {}
for house in existing_data:
    id = house["property_id"]
    amenities = house["amenities"]
    listings_dict[id] = amenities

    
# Function to recursively convert dictionary keys to strings
def convert_keys_to_string(data):
    if isinstance(data, dict):  # If the data is a dictionary
        # Recursively convert each key to a string and apply to the dictionary's values.
        return {str(key): convert_keys_to_string(value) for key, value in data.items()}
    elif isinstance(data, list):  # If the data is a list
        # Recursively convert all items in the list to strings.
        return [convert_keys_to_string(item) for item in data]
    else:  # If the data is neither a dictionary nor a list 
        return data

# # Load JSON Data (House Preferences)
# try:
#     with open("cur_data.json", "r") as file:
#         data = json.load(file)  # parse the JSON data from the file into a Python dictionary.
# except FileNotFoundError:  # If the file is not found
#     print("Error: cur_data.json not found.")  # Print an error message.
#     exit()  # Exit the program because the necessary data file is missing.

data = listings_dict
# Load Sample Labeled Data
labeled_data = [  # Create a list of tuples with preferences and their corresponding categories.
    ("Dogs Allowed", "Pet_Friendly"),
    ("Cat Park", "Pet_Friendly"),
    ("Package Receiving", "Security"),
    ("Gated Access", "Security"),
    ("Swimming Pool", "Amenities"),
    ("Fitness Center", "Amenities"),
    ("24-Hour Security", "Security"),
    ("Pet Washing Station", "Pet_Friendly"),
    ("Clubhouse", "Amenities"),
    ("Bicycle Storage", "Amenities"),
] 

# Convert labeled data into a DataFrame for easier manipulation
df = pd.DataFrame(labeled_data, columns=["Preference", "Category"]) 

# Convert Text into Sentence Embeddings using SentenceTransformer
embedding_model = SentenceTransformer('all-MiniLM-L6-v2')  # Load the pre-trained model from SentenceTransformers to generate sentence embeddings.

# Generate category embeddings for the predefined categories (Security, Amenities, Pet-Friendly)
category_embeddings = embedding_model.encode(df["Category"].unique())  # Generate embeddings for each unique category.

# Categorize New Preferences Using Cosine Similarity
categorized_data = {}  # Initialize an empty dictionary to store the categorized data.

# Confidence threshold: preferences with a similarity lower than this will be categorized as "Others"
confidence_threshold = 0.3  # Set a threshold for similarity 

# Explicit matching rules for categories like Security, Amenities
explicit_security_keywords = ["Package Receiving", "24-Hour Security", "Gated Access"]  # Define a list of keywords related to the Security category.
explicit_amenities_keywords = ["Swimming Pool", "Fitness Center", "Clubhouse"]  # Define a list of keywords related to the Amenities category.

# Iterate through the new preferences (data)
for house_id, details in data.items():  # For each house, use its ID and the corresponding preferences.
    new_preferences = details  # Extract the preferences for this house.
    house_categories = defaultdict(list)  # Use defaultdict to store categorized preferences for each house.

    for pref in new_preferences:  # Iterate through each preference for the house.
        # Embed the new preference using the pre-trained model
        pref_embedding = embedding_model.encode([pref])  # Generate the embedding for the preference.

        # Calculate cosine similarities between the preference and all category embeddings
        similarities = cosine_similarity(pref_embedding, category_embeddings)  # Compute the cosine similarity.

        # Get the category with the highest similarity
        best_match_idx = np.argmax(similarities)  # Find the index of the highest similarity.
        best_similarity = similarities[0][best_match_idx]  # Get the similarity value of the best match.

        # If similarity is below the threshold, classify as "Others"
        if best_similarity < confidence_threshold:  # If the similarity is lower than the threshold
            # Check for explicit keyword-based matches for Security or Amenities
            if any(keyword in pref for keyword in explicit_security_keywords):  # If any keyword for Security is in the preference
                category = "Security"  # Assign the category as Security.
            elif any(keyword in pref for keyword in explicit_amenities_keywords):  # If any keyword for Amenities is in the preference
                category = "Amenities"  # Assign the category as Amenities.
            else:
                category = "Others"  # If no match, assign the category as "Others".
        else:
            category = df["Category"].unique()[best_match_idx]  # Otherwise, use the category from the best match.

        house_categories[category].append(pref)  # Append the preference to the appropriate category.

    categorized_data[house_id] = dict(house_categories)  # Save the categorized preferences for the house.

#Save Categorized Data to JSON File
try:
    categorized_data_str = convert_keys_to_string(categorized_data)  # Convert all dictionary keys to strings for proper JSON formatting.
    
    with open("categorized_Data.json", "w") as output_file:  # Open a new file to save the categorized data.
        json.dump(categorized_data_str, output_file, indent=4)  # Dump the data to the file in JSON format with indentation.
except IOError: 
    print("Error writing to categorized_Data.json")  # Print an error message.

# __________INTEGRATION 2 _________
# SAVE CATEGORIZED DATA TO DB

# Print Sample Results
print("\nSample Categorized Data:")  # Print the sample categorized data.
for house_id, categories in list(categorized_data.items())[:3]:  # Loop through the first 3 houses in the categorized data.
    print(f"\nHouse ID: {house_id}")  # Print the house ID.
    for category, prefs in categories.items():  # For each category, print the list of preferences.
        print(f"  {category}: {prefs}")
