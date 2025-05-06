//
//  PropertyImageView.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 4/8/25.
//


import SwiftUI

struct PropertyImageView: View {
    let imageUrlString: String
    let address: String
    let location: String

    var body: some View {
        propertyImageLoaderView()
            .aspectRatio(contentMode: .fill)
            .frame(height: 350)
            .clipped()
            .overlay(
                LinearGradient(gradient: Gradient(colors: [.clear, .clear, .black.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
            )
    }

    @ViewBuilder
    private func propertyImageLoaderView() -> some View {
        if let imageUrl = URL(string: imageUrlString) {
            AsyncImage(url: imageUrl) { phase in
                if let image = phase.image {
                    image.resizable()
                } else if phase.error != nil {
                    // Error state view
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(Color.secondary.opacity(0.5))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                } else {
                    // Loading state view
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.1))
                }
            }
        } else {
            // Nil URL placeholder
            Image(systemName: "photo.fill")
                .font(.largeTitle)
                .foregroundColor(Color.secondary.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
        }
    }
}
