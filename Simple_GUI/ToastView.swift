//
//  ToastView.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 4/7/25.
//

import SwiftUICore

struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.green)
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}
