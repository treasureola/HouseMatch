//
//  Profile.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/26/25.
//

import SwiftUI

struct Profile: View {

    //4N. To help access the shared 'UserInfo' object
    @EnvironmentObject var userInfo: UserInfo
    
    var body: some View {
        ScrollView{
            VStack(spacing: 20){
                
                Text("Profile Page:")
                    .font(.headline)
                //1. For our profile heading
                ZStack{ //used ZStack for the layering purpose
                    Color.purple
                        .frame(height: 135)
                        .edgesIgnoringSafeArea(.horizontal)
                    
                    VStack{
                        Image(.houseA)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle()) //this clips the image in a circle form
                            .overlay(Circle().stroke(Color.white, lineWidth: 2)) //this create an white overlay
                            .shadow(radius: 20)  //the shadown contrast
                        
                        //2. For user's profile name on top
                        HStack{
                            Text("\(userInfo.firstName) \(userInfo.lastName)")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.top, 60) //padding at the top of the page
            }
            //3. To display the Account Details
            VStack(alignment: .leading, spacing: 15){
                Text("Account Details")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                HStack{
                    Image(systemName: "mail")
                        .foregroundColor(.orange)
                    Text("\(userInfo.email)")
                    Spacer()
                    
                }
                HStack{
                    Image(systemName: "phone")
                        .foregroundColor(.orange)
                    Text("123-456-7890")
                    Spacer()
                }
                
            }
            .padding() //added some space
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))//for the overlay of a ligth gray background color
            .padding(.horizontal) //adds some padding on both sides
            
            //4. Saved Preferences
            .padding(.bottom, 20)
            VStack(alignment: .leading, spacing: 15){
                Text("Saved Preferences")
                    .font(.headline)
                    .foregroundColor(.purple)
                //property #1
                HStack{
                    Image("singleFamily_House")
                        .resizable()
                        .frame(width: 100, height: 100)
                    VStack(alignment: .leading){
                        Text("Single Family Home")
                    }
                        .foregroundColor(.orange)
                    Spacer()
        
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                
                //property #2
                HStack{
                    Image("TownHouse1")
                        .resizable()
                        .frame(width: 100, height: 100)
                    VStack(alignment: .leading){
                        Text("Townhouse")
                    }
                    .foregroundColor(.orange)
                    Spacer()
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                
                //property #3
                HStack{
                    Image("Condo11")
                        .resizable()
                        .frame(width: 100, height: 100)
                    VStack(alignment: .leading){
                        Text("Condo")
                    }
                    .foregroundColor(.orange)
                    Spacer()
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
            }
            .padding(.horizontal)
         

            NavigationLink(destination: LoginScreenView(username: "", theEmail: "", thePassword: "")){
                Text("Log Out")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 20).stroke(Color.red))
            }
        }
    }
}

#Preview {
    Profile()
        .environmentObject(UserInfo())
}

