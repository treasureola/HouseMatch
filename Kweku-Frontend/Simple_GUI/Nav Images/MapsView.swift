//
//  MapsView.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/25/25.
//

import SwiftUI

struct MapsView: View {
    var body: some View {
        ZStack{
            Color.green
            
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.white)
                .font(.system(size: 90))
            
        }
    }
}

#Preview {
    MapsView()
}
