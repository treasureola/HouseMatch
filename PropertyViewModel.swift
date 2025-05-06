//
//  PropertyViewModel.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftUI

class PropertyViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading = false
    @Published var fetchErrorMessage: String? = nil

    private var lastDocumentSnapshot: DocumentSnapshot?
    private var isFetchingMore = false
    private var backendRecommendations: [String: Float]?

    // Main entry point for fetching
    func fetchProperties(userInfo: UserInfo, isInitialLoad: Bool, completion: ((Bool) -> Void)? = nil) {
        guard !isLoading else {
            print("Already fetching, skipping.")
            completion?(false)
            return
        }

        print("Attempting to fetch properties... Initial Load: \(isInitialLoad)")
        self.isLoading = true
        self.fetchErrorMessage = nil

        if isInitialLoad {
            self.properties = []
            self.lastDocumentSnapshot = nil
            self.backendRecommendations = nil
        } else {
             guard !isFetchingMore else {
                 print("Already fetching more, skipping.")
                 self.isLoading = false
                 completion?(false)
                 return
             }
             isFetchingMore = true
        }

        guard let userID = Auth.auth().currentUser?.uid else {
             // Pass isInitialLoad here
            handleFetchError("Not logged in.", isInitialLoad: isInitialLoad, completion: completion)
            return
        }

        print("User authenticated. New User: \(userInfo.isNewUser)")
        let db = Firestore.firestore()

        db.collection("users").document(userID).getDocument { [weak self] (document, error) in
             guard let self = self else { return }

            if let error = error {
                print("Error fetching user preferences: \(error.localizedDescription)")
                 // Pass isInitialLoad here
                self.handleFetchError("Error fetching preferences.", isInitialLoad: isInitialLoad, completion: completion)
                return
            }

            guard let document = document, document.exists,
                  let userPreferences = document.data()?["preferences"] as? [String: Any],
                  let location = userPreferences["location"] as? String else {
                print("No preferences or location found for user.")
                 let message = userInfo.hasPreferences ? "Could not load preferences. Please try again." : "Please set your preferences first."
                 // Pass isInitialLoad here
                self.handleFetchError(message, isInitialLoad: isInitialLoad, completion: completion)
                return
            }

            // --- Decide Fetching Strategy ---
             if isInitialLoad {
                 if userInfo.isNewUser {
                    print("Fetching initial 25 properties for new user.")
                    let query = db.collection("properties")
                        .whereField("assignedUserID", isEqualTo: userID)
                        .whereField("viewed", isEqualTo: false)
                        .whereField("city", isEqualTo: location)
                        .limit(to: 25)
                     self.executeQueryAndProcess(query: query, forUserID: userID, location: location, db: db, isInitialLoad: isInitialLoad, isPaginated: true, userInfo: userInfo, userPreferences: userPreferences, scores: nil, completion: completion)

                 } else {
                    print("Fetching initial properties for existing user using recommendations...")
                    self.fetchFromBackendRecommendations(userID: userID) { [weak self] scores in
                         guard let self = self else { return }
                        if let scores = scores, !scores.isEmpty {
                             print("Successfully fetched recommendations.")
                             self.backendRecommendations = scores
                             let sortedIDs = scores.sorted { $0.value > $1.value }.map { $0.key }
                             let topIDs = Array(sortedIDs.prefix(20))

                            if topIDs.isEmpty {
                                 print("Recommendation scores received, but no IDs to fetch. Falling back.")
                                 self.fetchFallbackProperties(userID: userID, location: location, db: db, isInitialLoad: isInitialLoad, userInfo: userInfo, userPreferences: userPreferences, completion: completion)
                            } else {
                                 print("Fetching specific properties based on recommendations: \(topIDs)")
                                 let query = db.collection("properties")
                                     .whereField("property_id", in: topIDs)
                                     // Add .whereField("viewed", isEqualTo: false) if backend recs don't filter viewed properties
                                 self.executeQueryAndProcess(query: query, forUserID: userID, location: location, db: db, isInitialLoad: isInitialLoad, isPaginated: false, userInfo: userInfo, userPreferences: userPreferences, scores: scores, completion: completion)
                            }

                        } else {
                            print("Failed to get recommendations or recommendations empty, falling back to general query.")
                            self.fetchFallbackProperties(userID: userID, location: location, db: db, isInitialLoad: isInitialLoad, userInfo: userInfo, userPreferences: userPreferences, completion: completion)
                        }
                    }
                 }
             } else { // Not initial load - fetch next page
                 print("Fetching next page of properties...")
                 var query = db.collection("properties")
                     .whereField("assignedUserID", isEqualTo: userID)
                     .whereField("viewed", isEqualTo: false)
                     .whereField("city", isEqualTo: location)
                     .limit(to: 50)

                if let lastSnapshot = self.lastDocumentSnapshot {
                    query = query.start(afterDocument: lastSnapshot)
                 } else {
                      print("Warning: Fetching more without a pagination marker (lastDocumentSnapshot is nil).")
                      if fetchErrorMessage == "No more properties found." {
                           // Pass isInitialLoad here (it will be false in this case)
                           handleFetchError(nil, isInitialLoad: isInitialLoad, completion: completion)
                           return
                      }
                 }
                 self.executeQueryAndProcess(query: query, forUserID: userID, location: location, db: db, isInitialLoad: isInitialLoad, isPaginated: true, userInfo: userInfo, userPreferences: userPreferences, scores: self.backendRecommendations, completion: completion)
            }
        }
    }

    // Helper for fallback query
    private func fetchFallbackProperties(userID: String, location: String, db: Firestore, isInitialLoad: Bool, userInfo: UserInfo, userPreferences: [String: Any], completion: ((Bool) -> Void)?) {
         let fallbackQuery = db.collection("properties")
            .whereField("assignedUserID", isEqualTo: userID)
            .whereField("viewed", isEqualTo: false)
            .whereField("city", isEqualTo: location)
            .limit(to: 50)

        executeQueryAndProcess(query: fallbackQuery, forUserID: userID, location: location, db: db, isInitialLoad: isInitialLoad, isPaginated: true, userInfo: userInfo, userPreferences: userPreferences, scores: nil, completion: completion)
    }

    // Centralized function to execute query and process results
    private func executeQueryAndProcess(query: Query, forUserID userID: String, location: String, db: Firestore, isInitialLoad: Bool, isPaginated: Bool, userInfo: UserInfo, userPreferences: [String: Any], scores: [String: Float]?, completion: ((Bool) -> Void)?) {

        print("Executing Firestore query...")
        query.getDocuments { [weak self] (snapshot, error) in
             guard let self = self else { return }

             if !isInitialLoad { self.isFetchingMore = false }

            if let error = error {
                print("Error fetching properties from Firestore: \(error.localizedDescription)")
                 // Pass isInitialLoad here
                self.handleFetchError("Error loading properties.", isInitialLoad: isInitialLoad, completion: completion)
                return
            }

            guard let snapshot = snapshot else {
                print("Firestore query returned nil snapshot.")
                 // Pass isInitialLoad here
                self.handleFetchError("Failed to load properties.", isInitialLoad: isInitialLoad, completion: completion)
                return
            }

            // --- Handle Empty Snapshot ---
            if snapshot.isEmpty {
                print("Firestore query returned no documents.")
                 if self.fetchErrorMessage != "No more properties found." && self.fetchErrorMessage != "API fetch failed." {
                     print("Attempting API fetch as Firestore returned empty.")
                     self.fetchAndStoreFromAPI(userPreferences: userPreferences, userID: userID, db: db) { apiSuccess in
                        if apiSuccess {
                             print("API fetch successful, reloading from Firestore.")
                             self.lastDocumentSnapshot = nil
                             self.backendRecommendations = nil
                             self.fetchProperties(userInfo: userInfo, isInitialLoad: true, completion: completion)
                        } else {
                             print("API fetch failed or returned no new properties.")
                              // Pass isInitialLoad here
                             self.handleFetchError("No more properties found.", isInitialLoad: isInitialLoad, completion: completion)
                        }
                    }
                 } else {
                      print("Firestore empty, and previous attempt (API?) also yielded nothing. Reporting no more properties.")
                       // Pass isInitialLoad here
                      self.handleFetchError("No more properties found.", isInitialLoad: isInitialLoad, completion: completion)
                 }
                return
            }

            // --- Process Documents ---
            print("Processing \(snapshot.documents.count) documents from Firestore.")
            if isPaginated {
                self.lastDocumentSnapshot = snapshot.documents.last
                 print("Updated lastDocumentSnapshot to: \(self.lastDocumentSnapshot?.documentID ?? "nil")")
            } else {
                 print("Query was not paginated, not updating lastDocumentSnapshot.")
            }

            let newProperties = snapshot.documents.compactMap { doc -> Property? in
                 let data = doc.data()
                if !isInitialLoad && self.properties.contains(where: { $0.id == doc.documentID }) {
                    print("Skipping duplicate property ID: \(doc.documentID)")
                    return nil
                }
                let amenitiesArray = data["amenities"] as? NSArray ?? []
                let amenities = amenitiesArray.compactMap { $0 as? String }
                 let propertyID = data["property_id"] as? String ?? ""
                 let recommendationScore = scores?[propertyID] ?? (data["recommendation_score"] as? Float) ?? 0

                return Property(
                    id: doc.documentID,
                    propertyID: propertyID,
                    listingID: data["listing_id"] as? String ?? "",
                    listingURL: data["listing_url"] as? String ?? "",
                    status: data["status"] as? String ?? "Unknown",
                    imageUrl: data["photo_url"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    location: "\(data["city"] as? String ?? ""), \(data["state_code"] as? String ?? "")",
                    price: data["price"] as? Int ?? 0,
                    bedrooms: data["bedrooms"] as? Int ?? 0,
                    bathrooms: data["bathrooms"] as? Int ?? 0,
                    squareFeet: data["square_feet"] as? Int ?? 0,
                    amenities: amenities,
                    petFriendly: data["petFriendly"] as? Bool ?? false,
                    recommendationScore: recommendationScore
                )
            }

            DispatchQueue.main.async {
                 if isInitialLoad && !isPaginated && scores != nil {
                     print("Replacing properties with recommendations.")
                     self.properties = newProperties
                 } else {
                     print("Appending \(newProperties.count) properties.")
                    self.properties.append(contentsOf: newProperties)
                 }

                print("Total properties now: \(self.properties.count)")
                self.isLoading = false
                 self.fetchErrorMessage = nil
                completion?(true)
            }
        }
    }

     // Centralized error handling - MODIFIED SIGNATURE
     private func handleFetchError(_ message: String?, isInitialLoad: Bool, completion: ((Bool) -> Void)?) {
         DispatchQueue.main.async {
             self.isLoading = false
             if self.properties.isEmpty {
                self.fetchErrorMessage = message
             } else if message != nil && message != "No more properties found." { // Avoid overwriting final message
                 print("Fetch error occurred but existing properties remain: \(message!)")
                 // Optionally set a non-blocking error message here if needed
             } else if message == "No more properties found." {
                 self.fetchErrorMessage = message // Ensure final message is set
             }

             // Now isInitialLoad is in scope
             if !isInitialLoad {
                 self.isFetchingMore = false // Reset flag on error too
                 print("Reset isFetchingMore flag due to error during non-initial load.")
             }
             completion?(false)
         }
     }

    // --- Backend Recommendation Fetching ---
    private func fetchFromBackendRecommendations(userID: String, completion: @escaping ([String: Float]?) -> Void) {
        // implement userid as --> \(userid( since it is subjected to change and can not be hardcoded
        guard let url = URL(string: "http://3.213.132.205:8080/recommendations/\(userID)") else {
            print("Invalid backend URL")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling backend: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data from backend.")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let recs = json["recommendations"] as? [String: Float] {
                    completion(recs)
                } else {
                    print("Unexpected response format")
                    completion(nil)
                }
            } catch {
                print("JSON decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }

     // --- API Fetching Logic ---
    private func fetchAndStoreFromAPI(userPreferences: [String: Any], userID: String, db: Firestore, completion: @escaping (Bool) -> Void){
        print("Fetching Properties")
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found.")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userID)
        
        userDoc.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user preferences: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let document = document, document.exists,
                  let userPreferences = document.data()?["preferences"] as? [String: Any] else {
                print("No preferences found for user.")
                completion(false)
                return
            }
            
            guard let location = userPreferences["location"] as? String else {
                print("Error: Missing or invalid user preferences.")
                completion(false)
                return
            }
            
            let propertiesCollection = db.collection("properties")
            propertiesCollection.whereField("assignedUserID", isEqualTo: userID)
                .whereField("viewed", isEqualTo: false)
                .whereField("city", isEqualTo: location)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error checking existing properties: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    let existingUnviewedCount = snapshot?.documents.count ?? 0
                    if existingUnviewedCount >= 100 {
                        print("User already has 100 unviewed properties, skipping fetch.")
                        DispatchQueue.main.async{
                            completion(true)
                        }
                        return
                    }
                    
                    self.fetchFromAPI(
                        userPreferences: userPreferences,
                        userID: userID,
                        db: db
                    ) { success in
                        completion(success)
                    }
                }
        }
     }
    
    func fetchFromAPI(userPreferences: [String: Any], userID: String, db: Firestore, completion: @escaping (Bool) -> Void) {
        
        guard let location = userPreferences["location"] as? String,
              let maxPrice = userPreferences["maxPrice"] as? Int,
              let bedrooms = userPreferences["bedrooms"] as? String,
              let bathrooms = userPreferences["bathrooms"] as? String else {
            print("Error: Missing or invalid user preferences.")
            completion(false)
            return
        }
        
    
        // Format query parameters based on user preferences
        let formattedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
        let urlString = "https://realtor-search.p.rapidapi.com/properties/search-rent?location=city:\(formattedLocation)&price_max=\(maxPrice)&beds_min=\(bedrooms)&baths_min=\(bathrooms)&resultsPerPage=100&sortBy=best_match"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("41074491b8msh897384f5dfbdfd4p122b3cjsn3bf3b6b434f6", forHTTPHeaderField: "x-rapidapi-key")
        request.setValue("realtor-search.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error fetching properties from API: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let data = data else {
                print("No data received from API")
                completion(false)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let results = json?["data"] as? [String: Any],
                      let properties = results["results"] as? [[String: Any]] else {
                    print("Invalid response format from API")
                    completion(false)
                    return
                }
                
                if properties.isEmpty {
                    print("No new properties found matching criteria from API")
                    completion(true)
                    return
                }

                let group = DispatchGroup()
                let db = Firestore.firestore()
                let propertiesCollection = db.collection("properties")

                for property in properties {
                    
                    group.enter()
                    
                    let priceValue: Int
                    if let priceAny = property["list_price_max"] {
                        if let priceInt = priceAny as? Int {
                            priceValue = priceInt
                        } else if let priceDouble = priceAny as? Double {
                            priceValue = Int(priceDouble) // Convert Double to Int if necessary
                        } else {
                            priceValue = 0 // Default price
                        }
                    } else {
                        priceValue = 0 // Default price
                    }

                    let bedsValue: Int
                     if let bedsAny = (property["description"] as? [String: Any])?["beds_max"] {
                         if let bedsInt = bedsAny as? Int {
                             bedsValue = bedsInt
                         } else if let bedsDouble = bedsAny as? Double {
                            bedsValue = Int(bedsDouble)
                         } else {
                             bedsValue = 0
                         }
                     } else {
                         bedsValue = 0
                     }

                    let bathsValue: Int
                     if let bathsAny = (property["description"] as? [String: Any])?["baths_max"] {
                         if let bathsInt = bathsAny as? Int {
                            bathsValue = bathsInt
                         } else if let bathsDouble = bathsAny as? Double {
                            bathsValue = Int(bathsDouble)
                         } else {
                             bathsValue = 0
                         }
                     } else {
                         bathsValue = 0
                     }

                    let sqftValue: Int
                     if let sqftAny = (property["description"] as? [String: Any])?["sqft_max"] {
                         if let sqftInt = sqftAny as? Int {
                            sqftValue = sqftInt
                         } else if let sqftDouble = sqftAny as? Double {
                             sqftValue = Int(sqftDouble)
                         } else {
                             sqftValue = 0
                         }
                     } else {
                         sqftValue = 0
                     }

                    let amenitiesArray = ((property["details"] as? [[String: Any]])?
                        .compactMap { $0["text"] as? [String] }
                        .flatMap { $0 }
                    ) ?? []

                     let petPolicy = property["pet_policy"] as? [String: Any]
                     let catsAllowed = petPolicy?["cats"] as? Bool ?? false
                     let dogsAllowed = petPolicy?["dogs"] as? Bool ?? false



                    let propertyData: [String: Any] = [
                        "property_id": property["property_id"] as? String ?? "",
                        "listing_id": property["listing_id"] ?? "",
                        "status": property["status"] ?? "Unknown",
                        "photo_url": (property["primary_photo"] as? [String: Any])?["href"] ?? "",
                        "address": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["line"] as? String ?? "",
                        "city": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["city"] ?? "",
                        "state_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["state_code"] ?? "",
                        "postal_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["postal_code"] ?? "",
                        "price": priceValue,
                        "bedrooms": bedsValue,
                        "bathrooms": bathsValue,
                        "square_feet": sqftValue,
                        "listing_url": property["href"] ?? "",
                        "amenities": amenitiesArray,
                        "petFriendly": catsAllowed || dogsAllowed,
                        "assignedUserID": userID,
                        "viewed": false,
                        "clicks": false,
                        "entry_timestamp": FieldValue.serverTimestamp(),
                        "exit_timestamp": FieldValue.serverTimestamp(),
                        "timestamp": FieldValue.serverTimestamp(),
                        "favorited": false,
                        "rating": 0,
                        "total_time": 0
                    ]

                    // Saves the property data to Firestore
                    propertiesCollection.addDocument(data: propertyData) { error in
                        if let error = error {
                            print("Error saving property to Firestore: \(error.localizedDescription)")
                        } else {
                            print("Property successfully saved!")
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main){
                    print("All properties saved!")
                    completion(true)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(false)
            }
        }
        dataTask.resume()
    }
}
