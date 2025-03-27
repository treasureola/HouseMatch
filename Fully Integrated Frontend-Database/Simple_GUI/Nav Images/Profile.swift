//
//  Profile.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 2/16/25.
//


//
//  Profile.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/26/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct Profile: View {
    
    //4N. To help access the shared 'UserInfo' object
    @EnvironmentObject var userInfo: UserInfo
    @State private var likedHomes: [LikedHome] = []
    
    var body: some View {
        ScrollView{
            VStack(spacing: 20){
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
                            Text(userInfo.firstName + " " + userInfo.lastName)
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                            
                            
                        }
                    }
                }
                .padding(.top, 60) //padding at the top of the page
                                   //            }
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
                }
                .padding() //added some space
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))//for the overlay of a ligth gray background color
                .padding(.horizontal) //adds some padding on both sides
                
                //4. Saved Preferences
                .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 15){
                    Text("Liked Homes")
                        .font(.headline)
                        .foregroundColor(.purple)
                    
                    if likedHomes.isEmpty{
                        Text("No liked homes yet.")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(likedHomes) { home in
                            LikedHomeRow(home: home)
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear{
                    fetchUserInfo()
                    fetchLikedHomes()
                }
                
                
                
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
    
    func fetchUserInfo() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No authenticated user found.")
            return
        }

        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userID)

        userDoc.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user info: \(error.localizedDescription)")
                return
            }

            guard let data = document?.data() else {
                print("No user data found in Firestore.")
                return
            }

            DispatchQueue.main.async {
                userInfo.firstName = data["first_name"] as? String ?? "Unknown"
                userInfo.lastName = data["last_name"] as? String ?? "User"
                userInfo.email = data["email"] as? String ?? "No Email"
            }
        }
    }

        
    //fetch liked homes from firestore
    func fetchLikedHomes() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("likedHomes")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching liked homes: \(error.localizedDescription)")
                    return
                }

                let fetchedHomes: [LikedHome] = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return LikedHome(
                        id: doc.documentID,
                        address: data["address"] as? String ?? "Unknown Address",
                        price: data["price"] as? Int ?? 0,
                        bedrooms: data["bedrooms"] as? Int ?? 0,
                        bathrooms: data["bathrooms"] as? Int ?? 0,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        listingUrl: data["listingUrl"] as? String ?? ""
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.likedHomes = fetchedHomes
                }
            }
    }

}

