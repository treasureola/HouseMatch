//
//  SwipeablePropertiesView.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct SwipeablePropertiesView: View {
    @StateObject private var viewModel = PropertyViewModel()

    var body: some View {
        ZStack {
            if viewModel.properties.isEmpty {
                Text("No properties available")
                    .font(.headline)
                    .padding()
            } else {
                ForEach(viewModel.properties) { property in
                    PropertyCard(property: property) {
                        // Remove the property from the list when swiped
                        viewModel.properties.removeAll { $0.id == property.id }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            print("Fetching properties on appear...")
            viewModel.fetchProperties() // Fetch properties when view loads
        }
    }

    func removeProperty(_ property: Property) {
        withAnimation {
            viewModel.properties.removeAll { $0.id == property.id }
        }
    }
    
}
   
