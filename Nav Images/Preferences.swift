//
//  Preferences.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 2/16/25.
//


//
//  Preferences.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/27/25.
//

import SwiftUI

struct Preferences: View {
    @State private var navigateToConfirmation = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                
                //Blueish-green background gradient
                //with the top color as: blue
                //bottom color as: green
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                
                VStack{
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.white)
                        .font(.system(size: 90))
                        .padding(.top, 50)
                    
                    Text("Edit Your Experience")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Set your preferences to find your dream home.")
                        .foregroundColor(.white.opacity(1.0))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Spacer()
                    
                    //This would redirect to the preference page
                    Button(action: {
                        navigateToConfirmation = true // Trigger navigation
                    }) {
                        HStack{
                            Text("Make preferences")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $navigateToConfirmation){
                FindDreamHome()
            }
        }
    }
}

#Preview {
    Preferences()
}
