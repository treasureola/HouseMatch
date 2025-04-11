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
    @State private var activePropertyID: String?

    var body: some View {
        ZStack {
            if viewModel.properties.isEmpty {
                Text("Loading...")
                    .font(.headline)
                    .padding()
            } else {
                ForEach(viewModel.properties) { property in
                    PropertyCard(property: property, onRemove: {
                        // Remove the property from the list when swiped
                        viewModel.properties.removeAll { $0.id == property.id }

                        // Set the next property as active
                        if let nextProperty = viewModel.properties.first {
                            activePropertyID = nextProperty.id
                        } else {
                            activePropertyID = nil
                        }
                    }, activePropertyID: $activePropertyID)
                    .padding()
                }
            }
        }
        .onAppear {
            print("Fetching properties on appear...")
            print("in swipeablePropertiesView")
            viewModel.fetchProperties() // Fetch properties when view loads
            
            // Set the first property as active when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                activePropertyID = viewModel.properties.first?.id
            }
        }
    }

    func removeProperty(_ property: Property) {
        withAnimation {
            viewModel.properties.removeAll { $0.id == property.id }
        }
    }
    
}
   
