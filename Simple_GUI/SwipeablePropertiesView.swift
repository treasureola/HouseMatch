//
//  SwipeablePropertiesView.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//


import SwiftUI

struct SwipeablePropertiesView: View {
    @StateObject private var viewModel = PropertyViewModel()

    var body: some View {
        ZStack {
            ForEach(viewModel.properties) { property in
                PropertyCard(property: property) {
                    removeProperty(property)
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.fetchProperties() // Fetch properties when view loads
        }
    }

    func removeProperty(_ property: Property) {
        withAnimation {
            viewModel.properties.removeAll { $0.id == property.id }
        }
    }
}
