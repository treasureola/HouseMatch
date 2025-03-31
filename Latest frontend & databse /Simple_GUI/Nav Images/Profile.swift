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
    
    //New..to track whether we're in edit or delete mode
    @State private var isEditing = false
    @State private var deleteMode = false
    @State private var draggedItem: LikedHome?
    
    @State private var showLogoutError = false
    @State private var logoutError = ""
    
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
                
                //4. Like Homes
                .padding(.bottom, 20)
                
                VStack(alignment: .leading, spacing: 15){
                    HStack{
                        Text("Liked Homes")
                            .font(.headline)
                            .foregroundColor(.purple)
                        
                        
                        //New..the edit option button to switch between modes
                        Spacer()
                        
                        Menu {
                            Button("Rearrange"){
                                isEditing.toggle()
                                deleteMode = false
                            }
                            Button("Delete", role: .destructive){
                                deleteMode.toggle()
                                isEditing = false
                            }
                        } label: {
                            Text("Edit")
                                .foregroundStyle(.black)
                        }
                    }
                    
                    if likedHomes.isEmpty{
                        Text("No liked homes yet.")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        //New..creating a vertical stacked of list of liked homes
                        //lazyVStack's are good for long lists
                        LazyVStack(spacing: 10){
                            ForEach(likedHomes) { home in
                                let row = LikedHomeRow(home: home, isEditing: isEditing, deleteMode: deleteMode)
                                        
                                    //new..an overlay for the delete button
                                    .overlay(
                                        Group {
                                            if deleteMode {
                                                Button {
                                                    deleteHome(home)
                                                }label: {
                                                    Image(systemName: "minus.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white.clipShape(Circle()))
                                                }
                                                //this positions the delete button to the top-right
                                                .offset(x: -10, y: -10)
                                            }
                                        },
                                        alignment: .topTrailing //this overlays the delete button at the top-right
                                    )
                                //Allow dragging only in edit mode
                                if isEditing && !deleteMode {
                                    row
                                        //New..where we drag the individual liked homes
                                        .onDrag {
                                            self.draggedItem = home
                                            return NSItemProvider(object: home.id as NSString)
                                        }
                                        //New..when an item/likedhome is dropped of
                                        .onDrop(of: [.text], delegate: MyReorderingDrop(  //using drag-drop functionality
                                            currentItem: home,         //the likedhome being dropped on
                                            items: $likedHomes,        //for binding all likedhomes for (reordering)
                                            draggedItem: $draggedItem  //for tracking which item/likehomes is dragged
                                            
                                        ))
                                        .opacity(draggedItem?.id == home.id ? 0.5 : 1)
                                } else{
                                    row
                                }
                            }
                        }
                            
                    }
                }
                    
                .padding(.horizontal)
                
                
                Spacer(minLength: 30)
                
                Button(action: handleLogout){
                    Text("Log Out")
                        .foregroundColor(.red)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Profile")
        .onAppear{
//            fetchUserInfo()
            fetchLikedHomes()
        }
        .alert("Logout Error", isPresented: $showLogoutError){
            Button("OK", role: .cancel){
                print("User logging out")
            }
        } message: {
            Text(logoutError)
        }
    }
    
//    func fetchUserInfo() {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("No authenticated user found.")
//            return
//        }
//
//        let db = Firestore.firestore()
//        let userDoc = db.collection("users").document(userID)
//
//        userDoc.getDocument { (document, error) in
//            if let error = error {
//                print("Error fetching user info: \(error.localizedDescription)")
//                return
//            }
//
//            guard let data = document?.data() else {
//                print("No user data found in Firestore.")
//                return
//            }
//
//            DispatchQueue.main.async {
//                userInfo.firstName = data["first_name"] as? String ?? "Unknown"
//                userInfo.lastName = data["last_name"] as? String ?? "User"
//                userInfo.email = data["email"] as? String ?? "No Email"
//            }
//        }
//    }
     
        
        
    //New..to handle drag and drop reordering of liked homes
    struct MyReorderingDrop: DropDelegate {
        let currentItem: LikedHome         //the current likehome that is hovered over when dragging
        @Binding var items: [LikedHome]    //the array of likedhomes that would be reordered
        @Binding var draggedItem: LikedHome? //the dragged likehome
       
        //Step 1:
        //New..func is called continuously to determine the type of operation. In this case: (.move)
        func dropUpdated(info: DropInfo) -> DropProposal? {
                DropProposal(operation: .move)
            }
        
    
        //Step 2:
        //New..Func is called once when the dragged likehome is in the area of another likehome
        func dropEntered(info: DropInfo) {
              
              //1. we check for a dragged likedhome
              //2. we find its current index
              //3. we find the index of the hovered likehome
              //4. we make sure we not dropping likehome at the same position (not dropping on itself)
              guard let draggedItem = draggedItem,
                    let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
                    let toIndex = items.firstIndex(where: { $0.id == currentItem.id }),
                    fromIndex != toIndex else { return }
              
            //Two ways: dragging up or down
            //when dragging down (toIndex > fromIndex), insert after current item(toIndex + 1)
            //when dragging up, insert before the current item
            let newOffset = toIndex > fromIndex ? toIndex + 1 : toIndex
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                  items.move(fromOffsets: IndexSet(integer: fromIndex),
                             toOffset: newOffset)           //this moves the likehome from its original pos to new pos
              }
          }
        
        //Step 3:
        //New..Func is called once when user releases (drop completes)
        func performDrop(info: DropInfo) -> Bool {
            draggedItem = nil  //resets
            return true       //successful drop
        }
        
    }
        
        
        
    //New..Function to delete/remove liked homes from UI and firebase db
    private func deleteHome(_ home: LikedHome) {
       guard let index = likedHomes.firstIndex(where: { $0.id == home.id }) else { return }
       
       //Firebase deletion here
       guard let userID = Auth.auth().currentUser?.uid else { return }
       Firestore.firestore().collection("users").document(userID)
           .collection("likedHomes").document(home.id).delete()
       
       //UI deletion here
       withAnimation {
           likedHomes.remove(at: index)
       }
   }
        
        
    
        
    //fetch liked homes from firestore
    func fetchLikedHomes() {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("likedHomes")
            .order(by: "timestamp", descending: true)
            .getDocuments {
 snapshot,
 error in
                if let error = error {
                    print("Error fetching liked homes: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No liked homes found")
                    DispatchQueue.main.async {
                        self.likedHomes = []
                    }
                    return
                }

                let fetchedHomes: [LikedHome] =
                    snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return LikedHome(
                        id: data["propertyID"] as? String ?? "",
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
    
    func handleLogout(){
        do{
            try Auth.auth().signOut()
            print("Logged out successfully")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
            logoutError = "Failed to log out: \(signOutError.localizedDescription)"
            showLogoutError = true
        }
    }

}

