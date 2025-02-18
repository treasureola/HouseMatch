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
                        imageUrl: data["photo_url"] as? String ?? "",
                        address: data["city"] as? String ?? "Unknown City",
                        price: data["price_min"] as? Int ?? 0,
                        bedrooms: data["bedrooms_min"] as? Int ?? 0,
                        bathrooms: data["bathrooms_min"] as? Int ?? 0,
                        listingUrl: data["listing_url"] as? String ?? ""
                    )
                } ?? []
            }
        }
    }
}
