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
    
    //track which property
    @Binding var activePropertyID: String?
    
    //for ML
    @State private var entryTimestamp: Date?
    @State private var exitTimestamp: Date?
    @State private var totalViewTime: TimeInterval = 0
    @State private var clicked = false
    @State private var isFavorited = false
    
    var isActive: Bool{
        return activePropertyID == property.id
    }

    var body: some View {
        ZStack {
            color.edgesIgnoringSafeArea(.all)
            
            ScrollView{
                VStack {
                    if let imageUrl = URL(string: property.imageUrl) {
                        AsyncImage(url: imageUrl) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 300)
                        .cornerRadius(15)
                        .clipped()
                    }
                    
                    Text(property.address)
                        .font(.title)
                        .bold()
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
                    
                    if property.petFriendly {
                        Text("🐾 Pet-Friendly")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                    
                    Divider().padding(.vertical, 5)
                    
                    VStack(alignment: .leading) {
                        Text("Amenities:")
                            .font(.headline)
                            .padding(.top, 5)
                        
                        if property.amenities.isEmpty {
                            Text("No amenities listed")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        } else {
                            ForEach(property.amenities, id: \.self) { amenity in
                                Text("• \(amenity)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.top, 5)
                    
                    
                    Spacer()
                    
                    // Button to view more details
                    if let url = URL(string: property.listingURL){
                        Button(action: {
                            clicked = true
                            storeInteraction()
                            UIApplication.shared.open(url)
                        }){
                            Text("View Listing")
                                .foregroundColor(.blue)
                                .padding()
                        }
                    }
                    
                    //Favorite Button
                    Button(action: {
                        isFavorited.toggle()
                        storeInteraction()
                    }){
                        Text(isFavorited ? "⭐ Favorited" : "☆ Favorite")
                            .foregroundColor(.blue)
                            .padding()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .onChange(of: isActive){ newValue in
                    if newValue {
                        entryTimestamp = Date()
                    } else {
                        exitTimestamp = Date()
                        calculateTotalViewTime()
                        storeInteraction()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            exitTimestamp = Date()
                            calculateTotalViewTime()
                            storeInteraction()
                            
                            markPropertyAsViewed(property)
                            saveLikedProperty(property)
                            onRemove?() // Remove the card if swiped far enough
                            activePropertyID = nil
                        } else {
                            withAnimation {
                                offset = .zero
                                color = .white
                            }
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func calculateTotalViewTime() {
        if let entry = entryTimestamp, let exit = exitTimestamp {
            totalViewTime = exit.timeIntervalSince(entry)
        }
    }
    
    func determineRating() -> Int{
        
        if isFavorited {
            return 5
        }
        
        //change to 30 in future
        if totalViewTime > 10 {
            return 4
        }
        
        //change to 15 in the future
        if totalViewTime > 5 {
            return 3
        }
        
        if clicked{
            return 2
        }
        
        return 1
    }
    
    func storeInteraction(){
        guard let userID = Auth.auth().currentUser?.uid else{
            print("User not authenticated")
            return
        }
        
        let db = Firestore.firestore()
        let propertyRef = db.collection("properties").document(property.id)
        
        let interactionData: [String: Any] = [
            "clicks": clicked,
            "favorited": isFavorited,
            "rating": determineRating(),
            "entry_timestamp": entryTimestamp ?? Date(),
            "exit_timestamp": exitTimestamp ?? Date(),
            "total_time": totalViewTime,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        propertyRef.updateData(interactionData){ error in
            if let error = error {
                print("Error saving interaction: \(error.localizedDescription)")
            } else {
                print("Interaction recorded for property \(property.id)")
            }
        }
    }
    
    func markPropertyAsViewed(_ property: Property) {
        let db = Firestore.firestore()
        let propertyRef = db.collection("properties").document(property.id)

        propertyRef.updateData(["viewed": true]) { error in
            if let error = error {
                print("Error updating viewed status: \(error.localizedDescription)")
            } else {
                print("Property marked as viewed in Firestore: \(property.id)")
            }
        }
    }
    
    func saveLikedProperty(_ property: Property){
        guard let userID = Auth.auth().currentUser?.uid else{
            print("User not authenticated")
            return
        }
        
        let db = Firestore.firestore()
        let likedHomeData: [String: Any] = [
            "propertyID": property.propertyID,
            "address": property.address,
            "price": property.price,
            "bedrooms": property.bedrooms,
            "bathrooms": property.bathrooms,
            "imageUrl": property.imageUrl,
            "listingID": property.listingID,
            "listingURL": property.listingURL,
            "timestamp": Timestamp(),
            "favorite": isFavorited,
            "rating": determineRating()
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
