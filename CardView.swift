//
//  CardView.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 10/29/24.
//

import SwiftUI

struct propertyCardView: View {
    var typeOfBuilding: String
    var imageName: String
    var description: String
    
    @State private var offset: CGSize = .zero //location of the card, where we drag it and where it ends up
    @State private var color: Color = .blue  //initial state of the color
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Properties and Buildings")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 30)
        ZStack {
            Rectangle()
                .frame(width: 380 , height: 530)
                .border(.white, width: 6.0)
                .cornerRadius(4)
                .foregroundColor(color.opacity(0.9))
                .shadow(radius: 4)
            VStack {
                Text(typeOfBuilding)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .bold()

                Image(imageName)
                    .resizable()
                    .frame(width: 320)
                    .frame(height: 300)
                    .cornerRadius(10)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 40)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    withAnimation {
                        swippingColorChange(width: offset.width)
                    }
                    
                } .onEnded { _ in
                    withAnimation {
                        swippingCard(width: offset.width)
                        swippingColorChange(width: offset.width)
                    }
                    
                }
        )
    }
}
  
    //moves the Card either left or right and get rid of it
    func swippingCard(width: CGFloat){
        switch width {
        case -500...(-150):    //for the left swiping
            print("\(typeOfBuilding) removed")
            offset = CGSize(width: -500, height: 0)
        case 150...500:       //for the right swipinp
            print("\(typeOfBuilding) added")
            offset = CGSize(width: 500, height: 0)
        default:
            offset = .zero
            
        }
    }
    
    //changes the color depedding on where the color is
    func swippingColorChange(width: CGFloat){
        switch width {
            case -500...(-130):  //swipping to the left about (-130), turns red
            color = .red
            case 130...500:      //swipping to the right about (130), turns green
            color = .green
        default:
            color = .blue
            
        }
    }
}

#Preview {
    propertyCardView(typeOfBuilding: "Multi-Family Home", imageName: "Multi-Family_Home", description: "A residential multi-family building (2-4 units)")
}
