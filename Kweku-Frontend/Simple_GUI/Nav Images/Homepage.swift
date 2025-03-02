//
//  Homepage.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/26/25.
//

import SwiftUI

struct Homepage: View {
    var body: some View {
        ZStack{
            Color.purple
//                .edgesIgnoringSafeArea(.all)
            VStack{
                VStack{
                    Text("About Us")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.black)
                        .padding(.top, 40)
                    
                    
                    
    
                    Text("We are an AI-powered platform for matching ideal homes with tenants based on budget, location, preferences, and availability, while also helping landlords find suitable tenants in real time.")
                        .font(.body)
        
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .padding(.top, 40)

//                    
                    Spacer()
//

//                        Image(systemName: "house.fill")
//                            .foregroundColor(.white)
//                            .font(.system(size: 90))
            
                    
                    Image(.houseA)  //HouseMatch logo
                        .resizable()
                        .frame(width: 180, height: 180)
                        .cornerRadius(50)
                        .imageScale(.large)
                        .foregroundStyle(.blue)
                    
                    
                    Spacer()
                    
                    
                    //the link to view the properties available
                    NavigationLink(destination: PropertiesAndBuildingsSwipe()){
                        
                        Text("View Properties")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                    }
                    
                }
            }
        }
       
    }
}

#Preview {
    Homepage()
}
