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
            Color.orange
//                .edgesIgnoringSafeArea(.all)
            VStack{
                
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.white)
                    .font(.system(size: 90))
                    .padding(.top, 50)
                Spacer()
                
                NavigationLink(destination: FindDreamHome()){
                    
                    Text("Make preferences")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                }
            }
           
            

            
            
          
            
        }
       
        
    }
}

#Preview {
    Preferences()
}
