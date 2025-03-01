//
//  SwipeablePropertiesView.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 1/29/25.
//


import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct SwipeablePropertiesView: View {
    @StateObject private var viewModel = PropertyViewModel()

    var body: some View {
        ZStack {
            if viewModel.properties.isEmpty {
                Text("Loading properties...")
                    .font(.headline)
                    .padding()
                    .onAppear {
                        fetchRecommendationsAndProperties()
                    }
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
    }

    func removeProperty(_ property: Property) {
        withAnimation {
            viewModel.properties.removeAll { $0.id == property.id }
        }
    }
    
    func fetchRecommendationsAndProperties() {
        guard let user = Auth.auth().currentUser else {
            print("User not logged in")
            return
        }
        
        user.getIDToken { idToken, error in
            guard let idToken = idToken, error == nil else {
                print("Failed to get ID token: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Make API call to the backend to update recommendations
            let url = URL(string: "PUT IN THE ACTUAL URL")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(["id_token": idToken])
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error calling API: \(error)")
                    return
                }
                
                // Fetch updated properties after recommendations are stored
                DispatchQueue.main.async {
                    viewModel.fetchProperties()
                }
            }.resume()
        }
    }
}
   
