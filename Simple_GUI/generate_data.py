import json
import random

# --- Helper Functions ---

def generate_property_interaction(prop_id, user_id_pool):
    """Generates a single property dictionary."""
    bedrooms = random.randint(1, 5)
    bathrooms = random.randint(1, 4)
    price = random.randint(1000, 5000)
    sqft = random.randint(600, 2500)
    details = random.sample(possible_details, random.randint(5, 10))  # 5-10 details
    pet_friendly = random.choice([True, False])
    assigned_user_id = random.choice(user_id_pool)
    rating = random.randint(1, 5)
    favorited = rating >= 4
    clicked = rating >= 2 
    total_time = random.randint(5, 30)
    if rating == 5 or favorited:
        total_time = random.randint(60, 300)
    elif rating == 4:
        total_time = random.randint(30, 120)
    elif rating == 3:
        total_time = random.randint(15, 60)

    return {
        "property_id": prop_id,
        "bedrooms": bedrooms,
        "bathrooms": bathrooms,
        "price": price,
        "sqft": sqft,
        "details": details,
        "pet_friendly": pet_friendly,
        "assigned_user_id": assigned_user_id,
        "rating": rating,
        "favorited": favorited,
        "clicked": clicked,
        "total_time": total_time
    }

def generate_user_interaction(user_id, property_id):
    """Generates a single user interaction dictionary."""
    rating = random.randint(1, 5)
    favorited = random.choice([True, False])
    clicked = random.choice([True, False])
    total_time = random.randint(5, 120)
    return {
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
    "granite quartz countertops available",
    "open layouts", "private entrance", "airy 9-foot ceilings", "fishing lake",
    "barn doors available", "professional landscaping", "kitchen with island",
    "stainless steel appliances", "dogs allowed", "cats allowed"
]

# --- Generate Data ---

num_records = 2500
num_users = 50
num_properties = 200
user_ids = [f"user{i+1}" for i in range(num_users)]

generated_data_list = []
for i in range(num_records):
    prop_id = random.randint(1, num_properties)
    generated_data_list.append(generate_property_interaction(prop_id, user_ids))

# --- Output as JSON ---
# print(json.dumps(properties, indent=4))  # For just properties
# print(json.dumps(interactions, indent=4)) # for just interactions
print(json.dumps(generated_data_list, indent=4))   # Combined data


# --- To Create a pandas DataFrame---
import pandas as pd

df_synthetic = pd.DataFrame(generated_data_list)
# print(df_synthetic)  # Uncomment to view the DataFrame