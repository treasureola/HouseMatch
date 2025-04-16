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
    @EnvironmentObject var userInfo: UserInfo
    @State private var initialLoadComplete = false

    var body: some View {
        ZStack {
            if viewModel.isLoading && !initialLoadComplete{
                ProgressView("Loading Properties...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let errorMessage = viewModel.fetchErrorMessage {
                 VStack {
                     Text("Error")
                         .font(.title)
                     Text(errorMessage)
                         .foregroundColor(.red)
                         .multilineTextAlignment(.center)
                         .padding()
                     Button("Retry") {
                         // Clear error and retry fetch
                         viewModel.fetchErrorMessage = nil
                         viewModel
                             .fetchProperties(
                                userInfo: userInfo,
                                isInitialLoad: true
                             )
                     }
                     .padding()
                 }
            } else if viewModel.properties.isEmpty && initialLoadComplete{
                VStack {
                     if viewModel.isLoading { // Show loading when fetching more
                         ProgressView("Fetching more properties...")
                     } else {
                         Text("No more properties matching your criteria right now. Check back later!")
                             .multilineTextAlignment(.center)
                             .padding()
                         // Optional: Button to manually trigger API check/refresh
                         Button("Check for New Properties") {
                             viewModel.fetchProperties(userInfo: userInfo, isInitialLoad: false) // Trigger the fetch more logic
                         }
                         .bold()
                         .foregroundColor(.white)
                         .frame(width: 200, height: 50)
                         .padding(.vertical, 10)
                         .background(Color.blue)
                         .cornerRadius(20)
                         .padding(.top)
                     }
                 }
                .onAppear {
                    // Automatically trigger fetch more when view appears and properties are empty
                    // Only trigger if not already loading to avoid loops
                    if !viewModel.isLoading {
                         viewModel.fetchProperties(userInfo: userInfo, isInitialLoad: false) // Trigger fetch more logic
                    }
                 }
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
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                viewModel.fetchProperties(userInfo: userInfo, isInitialLoad: false)
                            }
                        }
                    }, activePropertyID: $activePropertyID)
                    .padding()
                }
            }
        }
        .onAppear {
            print("SwipeablePropertiesView appearing...")
            // Fetch properties only if the list is currently empty on appear
            if viewModel.properties.isEmpty {
                print("Initial fetch triggered on appear.")
                viewModel.fetchProperties(userInfo: userInfo, isInitialLoad: true) { success in
                    if success {
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Ensure properties load before setting active
                            activePropertyID = viewModel.properties.first?.id
                            initialLoadComplete = true // Mark initial load as done
                        }
                    } else {
                        initialLoadComplete = true // Mark as done even if fetch failed
                    }
                }
            } else {
                 print("Properties already loaded, skipping initial fetch on appear.")
                 initialLoadComplete = true // Already loaded
                 // Ensure activePropertyID is set if returning to the view
                 if activePropertyID == nil, let firstProp = viewModel.properties.first {
                     activePropertyID = firstProp.id
                 }
            }
        }
    }

    func removeProperty(_ property: Property) {
        withAnimation {
            viewModel.properties.removeAll { $0.id == property.id }
        }
    }
    
}
   
