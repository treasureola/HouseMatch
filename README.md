# HouseMatch

A swipe-based housing discovery app that learns what you actually like. Users swipe through property listings, and a hybrid recommendation engine — a neural behavior model combined with collaborative filtering — reorders the feed based on how they interact with each listing.

Built as a capstone project at The George Washington University.

---

## Overview

Most housing search tools make you fill out a filter form and then show you everything that matches. HouseMatch takes the opposite approach: it shows you listings, watches how you engage with them (clicks, dwell time, favorites, ratings), and infers your preferences from behavior rather than a form.

The system has three parts:

- **iOS app (SwiftUI)** — swipeable property cards, account management, saved preferences, and a map view for location-based browsing
- **Python API (FastAPI)** — serves recommendations, triggers model training, and syncs data to and from Firestore
- **Recommendation engine (TensorFlow + scikit-learn)** — a global neural model fine-tuned per user, blended with two collaborative-filtering signals

---

## Features

- Swipe-based property browsing with like/pass interactions
- User registration, authentication, and persisted preferences (Firebase)
- Property listings pulled from an external real estate API (RapidAPI Realtor Search)
- Map UI for geolocation-based property discovery
- Per-user recommendation scores, refreshed on demand or on a nightly schedule
- Hybrid scoring that combines learned behavior, similar-user activity, and preference similarity

---

## Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│   iOS Client    │ ──────▶ │   FastAPI API    │ ──────▶ │  ML_Model.py     │
│   (SwiftUI)     │ ◀────── │    (main.py)     │ ◀────── │  (TF + sklearn)  │
└────────┬────────┘         └────────┬─────────┘         └────────┬─────────┘
         │                           │                            │
         │                           ▼                            │
         │                  ┌──────────────────┐                  │
         └────────────────▶ │  Firebase /      │ ◀────────────────┘
                            │  Firestore       │
                            └──────────────────┘
                                     ▲
                                     │
                            ┌──────────────────┐
                            │  Realtor API     │
                            │  (listings)      │
                            └──────────────────┘
```

Firestore is the shared source of truth. The client writes interactions there; the API pulls them into local JSON snapshots (`db.json`, `user.json`) for training, and writes scored recommendations back out.

---

## How the recommendation engine works

### Feature vector

Each user–property interaction is encoded as a 12-dimensional vector:

| Interaction features | Static property features |
| --- | --- |
| clicks | price |
| viewed | bedrooms |
| total time on listing | bathrooms |
| entry timestamp (UNIX) | square footage |
| rating | location (hashed) |
| favorited (0/1) | property type (hashed) |

### Model

A feedforward binary classifier built in Keras, predicting whether a user will favorite a property:

- Input → Dense(128, ReLU, L2) → Dropout(0.4) → Dense(64, ReLU, L2) → Dropout(0.4) → Dense(1, sigmoid)
- Adam optimizer, binary cross-entropy loss
- Class weights computed with `sklearn.utils.class_weight` to handle the heavy imbalance between favorited and non-favorited listings
- Features scaled with `MinMaxScaler`, persisted alongside the model

A **global model** is trained across all users and saved to `global_model.h5`. For each user with enough interaction history (5+ listings), that model is cloned and fine-tuned on their data with early stopping, producing a personalized scorer.

### Three signals, weighted

Final scores merge three sources:

| Signal | Method | Default weight |
| --- | --- | --- |
| Behavior | Per-user fine-tuned neural model | 0.6 |
| Similar users | Cosine similarity over behavior + static preference vectors, top 5 neighbors | 0.3 |
| Preferences | Cosine similarity over averaged liked-property vectors, top 5 neighbors | 0.1 |

Collaborative signals are skipped when the dataset contains only one user. The top 100 scored properties per user are persisted.

### Evaluation

`calculate_final_accuracy()` reports top-K hit rate, precision, recall, and F1 against each user's actual favorited listings. A per-signal hit-rate check (`compute_hit_rate_accuracy`) runs at top-10 for the collaborative components.

---

## Tech stack

**Backend** — Python, FastAPI, Uvicorn, TensorFlow/Keras, scikit-learn, pandas, NumPy, SciPy, joblib, `schedule`

**Client** — Swift, SwiftUI, Xcode

**Data** — Firebase Authentication, Cloud Firestore, Firebase Admin SDK

**External APIs** — RapidAPI Realtor Search, Google Maps

---

## API reference

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/health` | Health check |
| `GET` | `/recommendations/{user_id}` | Refreshes that user's data from Firestore, loads or trains the model, and returns ranked recommendations |
| `POST` | `/train-and-generate` | Retrains the global model and regenerates recommendations for every user |
| `POST` | `/train-global` | Retrains the global model only |

A background thread also retrains the global model daily at 04:00.

---

## Getting started

Requires Python 3.10 or 3.11 (TensorFlow is unreliable on 3.12+), and Xcode 15+ for the client.

```bash
git clone https://github.com/treasureola/HouseMatch.git
cd HouseMatch

python3.11 -m venv venv && source venv/bin/activate
pip install fastapi uvicorn tensorflow scikit-learn pandas numpy scipy \
            joblib firebase-admin schedule
```

On Apple Silicon, swap `tensorflow` for `tensorflow-macos`.

### Run the engine on sample data

`ML_Model.py` reads the committed `db.json` snapshot directly, so no database connection is needed:

```bash
python ML_Model.py
```

This trains the global model, fine-tunes a model per user, writes the top 100 scored properties per user to `recommendations.json`, and prints hit rate, precision, recall, and F1. Takes a few minutes on CPU.

### Run the API

Add your Firebase service account key and update the path in `main.py`:

```python
cred = credentials.Certificate("path/to/your-service-account.json")
```

Run `python ML_Model.py` once before starting the server — `global_model.h5` is committed but its `scaler.pkl` is not, and the loader expects both. Then:

```bash
python main.py    # http://0.0.0.0:8000, interactive docs at /docs
```

```bash
curl http://localhost:8000/health
curl http://localhost:8000/recommendations/YOUR_FIREBASE_UID
```

The API reads from a Firestore `properties` collection, where each document is one user's interaction with one listing, keyed by `assignedUserID` and `property_id`. See the feature table above for the fields it expects.

### iOS client

Open `Simple_GUI.xcodeproj`, add your own `GoogleService-Info.plist` from the Firebase console, point the API base URL at your backend, and build.

---

## Repository structure

```
HouseMatch/
├── main.py                  # FastAPI server and endpoints
├── ML_Model.py              # Recommendation engine: training, scoring, evaluation
├── curModel.py              # Earlier model iteration
├── model.ipynb              # Model development notebook
├── generate_data.py         # Synthetic interaction data generator
├── ML/                      # ML assets and experiments
├── docs/                    # Project documentation
│
├── Simple_GUIApp.swift      # App entry point
├── AppEntryView.swift       # Root view / routing
├── ContentView.swift        # Main container view
├── SwipeablePropertiesView  # Swipe deck
├── PropertyCard.swift       # Card UI
├── PropertyViewModel.swift  # View model / state
├── Property.swift           # Property model
├── UserInfo.swift           # User model
│
├── db.json                  # Firestore snapshot (all properties)
├── global_model.h5          # Trained global model
└── recommendations.json     # Generated recommendation scores
```

---

## Known limitations

- Interaction data is partly synthetic; the model has not been validated against production-scale real user behavior
- Location and property type are hashed into integer buckets rather than properly encoded, which discards ordering and similarity information
- Per-user fine-tuning happens at request time, so the recommendations endpoint is slow under load
- Local JSON files sit between Firestore and the model, which works for a single instance but does not scale horizontally

## Roadmap

- Replace hash-bucketed categoricals with learned embeddings
- Precompute recommendations asynchronously instead of training on request
- Containerize the API and deploy behind a managed service
- Add automated tests and evaluation tracking across model versions

---

## Team

| Area | Contributor |
| --- | --- |
| Machine learning, map UI | Treasure Oluwalade |
| Frontend | Kweku |
| Data flow and schema | Syl |
| Backend, auth, geolocation | Issouf |
