//
//  PropertyCard.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//


import SwiftUI

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

                Text("$\(property.price)")
                    .font(.title)
                    .bold()

                HStack {
                    Text("\(property.bedrooms) Beds • \(property.bathrooms) Baths")
                        .font(.subheadline)
                }

                Spacer()

                // Button to view more details
                Link("View Listing", destination: URL(string: property.listingUrl)!)
                    .foregroundColor(.blue)
                    .padding()
            }
            .padding()
            .background(color.opacity(0.8))
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
                            onRemove?() // Remove the card if swiped far enough
                        } else {
                            offset = .zero
                            color = .white
                        }
                    }
            )
        }
    }
}
