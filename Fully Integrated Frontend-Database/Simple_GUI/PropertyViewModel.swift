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

    func fetchProperties() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            return
        }
        
        let db = Firestore.firestore()
        
        print("Database connected")
        db.collection("users").document(userID)
            .getDocument{ (document, error) in
                if let error = error {
                    print("Error fetching user preferences: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let userPreferences = document.data()?["preferences"] as? [String: Any],
                      let location = userPreferences["location"] as? String else {
                    print("No preferences found for user.")
                    return
                }
                
//                //call EC2 instance
//                self.triggerEC2(userID: userID)
                
                db.collection("properties")
                    .whereField("assignedUserID", isEqualTo: userID)
                    .whereField("viewed", isEqualTo: false)
                    .whereField("city", isEqualTo: location)
//                    .order(by: "recommendation_score", descending: true)
                    .limit(to: 25)
                    .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error fetching properties: \(error.localizedDescription)")
                        return
                    }

                    DispatchQueue.main.async {
                        self.properties = snapshot?.documents.compactMap { doc -> Property? in
                            let data = doc.data()
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
                                petFriendly: data["pet_policy.cats"] as? Bool == true || data["pet_policy.dogs"] as? Bool == true
//                                recommendationScore: data["recommendation_score"] as? Float ?? 0.0
                            )
                        } ?? []
                        
                    }
                }
            }
    }
    
//    func triggerEC2(userID: String) {
//        guard let url = URL(string: "http://your-ec2-public-ip:5000/run-ml?userID=\(userID)") else { return }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//
//        URLSession.shared.dataTask(with: request) { _, _, error in
//            if let error = error {
//                print("Error triggering EC2: \(error.localizedDescription)")
//            } else {
//                print("EC2 told to run ML model")
//            }
//        }.resume()
//    }

}
