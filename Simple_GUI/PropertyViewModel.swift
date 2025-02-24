//
//  PropertyViewModel.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//


import SwiftUI
import FirebaseFirestore

class PropertyViewModel: ObservableObject {
    @Published var properties: [Property] = []

    func fetchProperties() {
        let db = Firestore.firestore()
        db.collection("properties").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching properties: \(error.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                self.properties = snapshot?.documents.compactMap { doc -> Property? in
                    let data = doc.data()
                    return Property(
                        id: doc.documentID,
                        propertyID: data["property_id"] as? String ?? "",
                        listingID: data["listing_id"] as? String ?? "",
                        status: data["status"] as? String ?? "Unknown",
                        imageUrl: data["photo_url"] as? String ?? "",
                        address: "\(data["city"] as? String ?? ""), \(data["state_code"] as? String ?? "")",
                        priceMin: data["price_min"] as? Int ?? 0,
                        priceMax: data["price_max"] as? Int ?? 0,
                        bedrooms: data["bedrooms_max"] as? Int ?? 0,
                        bathrooms: data["bathrooms_max"] as? Int ?? 0,
                        squareFeet: data["square_feet_max"] as? Int ?? 0,
                        amenities: data["details"] as? [String] ?? [],
                        petFriendly: data["pet_policy.cats"] as? Bool == true || data["pet_policy.dogs"] as? Bool == true
                    )
                } ?? []
            }
        }
    }
}
