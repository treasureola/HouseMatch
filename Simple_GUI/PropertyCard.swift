//
//  PropertyCard.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct PropertyCard: View {
    let property: Property
    var onRemove: (() -> Void)? // Callback when card is swiped

    @State private var offset: CGSize = .zero
    @State private var color: Color = .white

    var body: some View {
        ZStack {
            VStack {
                if let imageUrl = URL(string: property.imageUrl) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 300)
                    .cornerRadius(15)
                }
                
                Text(property.address)
                    .font(.headline)
                    .padding(.top, 5)
                
                Text(property.location)
                    .font(.headline)
                    .padding(.top, 5)

                Text("$\(property.price)")
                    .font(.title)
                    .padding(.top, 5)
                    .bold()
                
                Text("\(property.bedrooms) Beds • \(property.bathrooms) Baths • \(property.squareFeet) sqft")
                                    .font(.subheadline)
                                    .padding(.vertical, 5)


                VStack(alignment: .leading) {
                    Text("Amenities:")
                        .font(.headline)
                        .padding(.top, 5)

                    ForEach(property.amenities, id: \.self) { amenity in
                        Text("• \(amenity)")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 5)

                if property.petFriendly {
                    Text("🐾 Pet-Friendly")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }

                Spacer()

                // Button to view more details
                if let url = URL(string: property.listingURL){
                    Link("View Listing", destination: url)
                        .foregroundColor(.blue)
                        .padding()
                }
                
            }
            .padding()
            .background(color)
            .cornerRadius(15)
            .shadow(radius: 5)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        self.offset = gesture.translation
                        self.color = offset.width > 0 ? .green : .red
                    }
                    .onEnded { _ in
                        if abs(offset.width) > 150 {
                            saveLikedProperty(property)
                            onRemove?() // Remove the card if swiped far enough
                        } else {
                            offset = .zero
                            color = .white
                        }
                    }
            )
        }
    }
    
    func saveLikedProperty(_ property: Property){
        guard let userID = Auth.auth().currentUser?.uid else{
            print("User not authenticated")
            return
        }
        
        let db = Firestore.firestore()
        let likedHomeData: [String: Any] = [
            "propertyID": property.id,
            "address": property.address,
            "price": property.price,
            "bedrooms": property.bedrooms,
            "bathrooms": property.bathrooms,
            "imageUrl": property.imageUrl,
            "listingID": property.listingID,
            "listingURL": property.listingURL,
            "timestamp": Timestamp()
        ]
        
        db.collection("users").document(userID).collection("likedHomes").document(property.id).setData(likedHomeData){ error in
            if let error = error {
                print("Error saving liked home: \(error.localizedDescription)")
            } else {
                print("Home liked and saved successfully!")
            }
        }
    }
}
