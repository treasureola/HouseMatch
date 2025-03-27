//
//  LikedHomeRow.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 2/26/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct LikedHomeRow: View {
    let home: LikedHome

    var body: some View {
        HStack {
            if let imageUrl = URL(string: home.imageUrl) {
                AsyncImage(url: imageUrl) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                .cornerRadius(10)
            }

            VStack(alignment: .leading) {
                Text(home.address)
                    .font(.headline)
                Text("$\(home.price)")
                    .font(.subheadline)
                Text("\(home.bedrooms) Beds • \(home.bathrooms) Baths")
                    .font(.footnote)
            }
            Spacer()
            if let url = URL(string: home.listingUrl) {
                Link("View", destination: url)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}
