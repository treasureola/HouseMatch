//
//  Preferences.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/27/25.
//

import SwiftUI

struct Preferences: View {
    var body: some View {
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
                
                Text("Customize Your Experience")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                  
                Text("Set your preference to find your dream home.")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                //This would redirect to the preference page
                NavigationLink(destination: FindDreamHome()){
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
                    .padding(.bottom, 20)
                    .shadow(color: Color.black.opacity(0.3), radius: 5)
                    .padding(.bottom, 20)
                    }
            }
        }
    }
}

#Preview {
    Preferences()
}
