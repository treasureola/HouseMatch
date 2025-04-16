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
    @Published var isLoading = true
    @Published var fetchErrorMessage: String? = nil
    @Published var didRetry = false

    func fetchProperties() {
        print("Attempting to fetch properties..")
        self.isLoading = true
        self.fetchErrorMessage = nil
        self.properties = []
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            self.isLoading = false
            self.fetchErrorMessage = "Not logged in."
            return
        }
        print("User authenticated")
        
        let db = Firestore.firestore()
        
        print("Database connected")
        
        db.collection("users").document(userID)
            .getDocument{ (document, error) in
                if let error = error {
                    print("Error fetching user preferences: \(error.localizedDescription)")
                    self.isLoading = false
                    self.fetchErrorMessage = "Error fetching preferences."
                    return
                }
                
                guard let document = document, document.exists,
                      let userPreferences = document.data()?["preferences"] as? [String: Any],
                      let location = userPreferences["location"] as? String else {
                            print("No preferences or location found for user.")
                            self.isLoading = false
                            return
                        }
                
//                //call EC2 instance
//                self.triggerEC2(userID: userID)
                
                db.collection("properties")
                    .whereField("assignedUserID", isEqualTo: userID)
                    .whereField("viewed", isEqualTo: false)
                    .whereField("city", isEqualTo: location)
                    .order(by: "recommendation_score", descending: true)
                    .limit(to: 100)
                    .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error fetching properties: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.fetchErrorMessage = "Error loading properties."
                        }
                        return
                    }

                    DispatchQueue.main.async {
                        self.properties = snapshot?.documents.compactMap { doc -> Property? in
                            let data = doc.data()
                            
                            guard let score = data["recommendation_score"] as? Float else {
                                return nil
                            }
                            
                            let amenitiesArray = data["amenities"] as? NSArray ?? []
                            let amenities = amenitiesArray.compactMap { $0 as? String } // Convert to Swift array
                            
                            return Property(
                                id: doc.documentID,
                                propertyID: data["property_id"] as? String ?? "",
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
                                petFriendly: data["pet_policy.cats"] as? Bool == true || data["pet_policy.dogs"] as? Bool == true,
                                recommendationScore: score
                            )
                        } ?? []
                        
                        if self.properties.isEmpty && !self.didRetry{
                            self.didRetry = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                print("Retrying fetch")
                                self.fetchProperties()
                            }
                        } else{
                            self.isLoading = false
                        }
                    }
                }
            }
    }
}
