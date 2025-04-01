import json
import sqlite3

# Load the JSON data
with open('home_data.json', 'r') as file:
    data = json.load(file)

# Extract relevant data from JSON
properties = data["data"]["results"]

# Connect to SQLite database (creates if it doesn't exist)
conn = sqlite3.connect('home_data.db')
cursor = conn.cursor()

# Create table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS homes (
        property_id TEXT PRIMARY KEY,
        listing_id TEXT,
        status TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        postal_code TEXT,
        lat REAL,
        lon REAL,
        beds INTEGER,
        baths REAL,
        sqft_min INTEGER,
        sqft_max INTEGER,
        price_min INTEGER,
        price_max INTEGER,
        last_sold_date TEXT,
        last_sold_price INTEGER
    )
''')

# Insert data into SQLite
for home in properties:
    try:
        property_id = home.get("property_id")
        listing_id = home.get("listing_id")
        status = home.get("status")
        address = home["location"]["address"].get("line", "")
        city = home["location"]["address"].get("city", "")
        state = home["location"]["address"].get("state", "")
        postal_code = home["location"]["address"].get("postal_code", "")
        lat = home["location"]["address"]["coordinate"].get("lat", None)
        lon = home["location"]["address"]["coordinate"].get("lon", None)
        beds = home["description"].get("beds", None)
        baths = home["description"].get("baths_max", None)
        sqft_min = home["description"].get("sqft_min", None)
        sqft_max = home["description"].get("sqft_max", None)
        price_min = home.get("list_price_min", None)
        price_max = home.get("list_price_max", None)
        last_sold_date = home.get("last_sold_date", None)
        last_sold_price = home.get("last_sold_price", None)

        cursor.execute('''
            INSERT INTO homes (property_id, listing_id, status, address, city, state, postal_code, lat, lon, beds, baths, sqft_min, sqft_max, price_min, price_max, last_sold_date, last_sold_price)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (property_id, listing_id, status, address, city, state, postal_code, lat, lon, beds, baths, sqft_min, sqft_max, price_min, price_max, last_sold_date, last_sold_price))
    
    except Exception as e:
        print(f"Error inserting data for {property_id}: {e}")

# Commit and close
conn.commit()
conn.close()

print("Database created successfully and data inserted!")
