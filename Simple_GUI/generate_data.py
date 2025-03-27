import json
import random

# --- Helper Functions ---

def generate_property(property_id):
    """Generates a single property dictionary."""
    bedrooms = random.randint(1, 5)
    bathrooms = random.randint(1, 3)
    price = random.randint(1000, 5000)
    sqft = random.randint(600, 2500)
    details = random.sample(possible_details, random.randint(5, 10))  # 5-10 details
    return {
        "property_id": f"prop{property_id}",
        "bedrooms": bedrooms,
        "bathrooms": bathrooms,
        "price": price,
        "sqft": sqft,
        "details": details,
    }

def generate_user_interaction(user_id, property_id):
    """Generates a single user interaction dictionary."""
    rating = random.randint(1, 5)
    favorited = random.choice([True, False])
    clicked = random.choice([True, False])
    total_time = random.randint(0, 120)
    return {
        "user_id": user_id,
        "property_id": property_id,
        "rating": rating,
        "favorited": favorited,
        "clicked": clicked,
        "total_time": total_time,
    }



# --- Define Possible Details (Amenities) ---

possible_details = [
    "pool", "garage", "hardwood floors", "central ac", "balcony",
    "fireplace", "stainless steel appliances", "gym", "close to transit",
    "large yard", "finished basement", "granite countertops",
    "updated kitchen", "pet-friendly", "washer dryer in-unit",
    "walk-in closet", "city view", "garden", "patio", "security system",
    "gated community", "concierge", "doorman", "elevator", "parking",
    "storage space", "high ceilings", "open floor plan", "natural light",
    "renovated", "new construction", "close to park", "close to schools",
    "close to shopping", "waterfront", "mountain view", "quiet neighborhood",
    "package receiving", "master bath", "large oversized windows",
     "berber carpeting in select bedrooms", "pet park", "open kitchen",
    "efficient appliances", "on-site maintenance", "kitchen with breakfast bar",
    "granite quartz countertops available", "one mile from gallaudet university",
    "open layouts", "private entrance", "airy 9-foot ceilings", "fishing lake",
    "barn doors available", "professional landscaping", "kitchen with island",
    "stainless steel appliances in select homes", "dogs allowed", "cats allowed"
]

# --- Generate Data ---

num_properties = 1000
num_users = 50  #  You can adjust the number of users
interactions_per_user = 5 # Adjust interactions per user

# 1. Generate Property Data
properties = [generate_property(i + 1) for i in range(num_properties)]

# 2. Generate User Interactions
interactions = []
for user_num in range(1, num_users + 1):
    user_id = f"user{user_num}"
    # Sample properties for each user to interact with
    interacted_property_ids = random.sample(
        [p["property_id"] for p in properties], interactions_per_user
    )
    for property_id in interacted_property_ids:
        interactions.append(generate_user_interaction(user_id, property_id))


# 3. Combine for Final JSON Structure (like Firestore output)
#    We'll create a list of combined interaction + property data.

combined_data = []
for interaction in interactions:
    property_info = next(
        p for p in properties if p["property_id"] == interaction["property_id"]
    )
    combined = {**interaction, **property_info}  # Merge dictionaries
    combined_data.append(combined)

# --- Output as JSON ---
# print(json.dumps(properties, indent=4))  # For just properties
# print(json.dumps(interactions, indent=4)) # for just interactions
print(json.dumps(combined_data, indent=4))   # Combined data (like your fetch_data_from_firestore)


# --- To Create a pandas DataFrame---
import pandas as pd

df_synthetic = pd.DataFrame(combined_data)
# print(df_synthetic)  # Uncomment to view the DataFrame