import sqlite3
import pandas as pd
import joblib
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_absolute_error

# Load data from SQLite
conn = sqlite3.connect('home_data.db')
df = pd.read_sql_query("SELECT * FROM homes", conn)
conn.close()

# Print missing values per column
print("Missing values per column before cleaning:")
print(df.isnull().sum())

# Drop rows with missing essential values
df.dropna(subset=["beds", "baths", "sqft_min", "price_min"], inplace=True)

# Check if the DataFrame is still empty
if df.empty:
    raise ValueError("All rows were removed after dropping missing values. Please check your database!")

# Convert categorical data to numerical values
label_encoders = {}
categorical_columns = ["city", "state"]

for col in categorical_columns:
    le = LabelEncoder()
    df[col] = le.fit_transform(df[col].astype(str))  # Convert to string before encoding
    label_encoders[col] = le  # Save encoder

# Scale numerical data (Check again if data is empty)
if df[["beds", "baths", "sqft_min"]].empty:
    raise ValueError("No data available after processing! Check dataset integrity.")

scaler = StandardScaler()
df[["beds", "baths", "sqft_min"]] = scaler.fit_transform(df[["beds", "baths", "sqft_min"]])

# Define input and output
X = df[["beds", "baths", "sqft_min", "city", "state"]]
y = df["price_min"]

# Split data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Train model
model = LinearRegression()
model.fit(X_train, y_train)

# Evaluate model
y_pred = model.predict(X_test)
mae = mean_absolute_error(y_test, y_pred)
print(f"Mean Absolute Error: {mae}")

# Save model and encoders
joblib.dump(model, "home_price_model.pkl")
joblib.dump(label_encoders, "label_encoders.pkl")
joblib.dump(scaler, "scaler.pkl")

print("Model training complete. Files saved!")
