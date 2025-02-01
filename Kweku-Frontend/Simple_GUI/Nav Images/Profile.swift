//
//  Profile.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/26/25.
//

import SwiftUI

struct Profile: View {
    var body: some View {
        ZStack{
            Color.blue
            
            Image(systemName: "person")
                .foregroundColor(.white)
                .font(.system(size: 90))
            
        }
    }
}

#Preview {
    Profile()
}
