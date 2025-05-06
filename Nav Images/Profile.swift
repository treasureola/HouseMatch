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
                                
                                if !isEditing{     //when a user exits editing mode..save the order (#6. Saving to DB)
                                    saveOrderOfLikedHome()
                                }
                                
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
                                            parent: self,       //was passed in for reference
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
//            backfillOrderingPositions()
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
        let parent: Profile      //passed in for reference
        let currentItem: LikedHome         //the current likehome that is hovered over when dragging
        @Binding var items: [LikedHome]    //the array of likedhomes that would be reordered
        @Binding var draggedItem: LikedHome? //the dragged likehome
        
       
       
        //Step 1:
        //New..func is called continuously to determine the type of operation. In this case: (.move)
        //this visually moves the item/likedhome to a new position
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
        //calling the saveOrderOfLikedHome() (#5. Saved to DB)
        func performDrop(info: DropInfo) -> Bool {
            draggedItem = nil  //resets
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                parent.saveOrderOfLikedHome() //we used 'parent' here because saveOrderOfLikedHome is an instance member of type Profile and can't be used on instance of another nested type
            }
            
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
//            .order(by: "timestamp", descending: true)
            .order(by: "orderingPos")   //fetching by orderingPos  (#2. Saving to DB)
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
//                        id: data["propertyID"] as? String ?? "",
                        id: doc.documentID,
                        address: data["address"] as? String ?? "Unknown Address",
                        price: data["price"] as? Int ?? 0,
                        bedrooms: data["bedrooms"] as? Int ?? 0,
                        bathrooms: data["bathrooms"] as? Int ?? 0,
                        imageUrl: data["imageUrl"] as? String ?? "",
                        listingUrl: data["listingUrl"] as? String ?? "",
                        orderingPos: data["orderingPos"] as? Int ?? 0   //for reordering  (#3. Saving to DB)
                    )
                } ?? []

                DispatchQueue.main.async {
                    self.likedHomes = fetchedHomes
                }
            }
    }
    
    
    
//    //Since previously liked homes were saved without orderingPos, those house/properties don't have the field
//    //we will have to backfill them
//    private func backfillOrderingPositions() {
//        guard let userID = Auth.auth().currentUser?.uid else { return }
//
//        Firestore.firestore()
//            .collection("users").document(userID)
//            .collection("likedHomes")
//            .getDocuments { snapshot, error in
//                guard let documents = snapshot?.documents else { return }
//
//                let batch = Firestore.firestore().batch()
//                for (index, document) in documents.enumerated() {
//                    // here only update documents missing orderingPos
//                    if document.data()["orderingPos"] == nil {
//                        batch.updateData(["orderingPos": index], forDocument: document.reference)
//                    }
//                }
//
//                batch.commit { error in
//                    if let error = error {
//                        print("Backfill failed: \(error.localizedDescription)")
//                    } else {
//                        print("Successfully backfilled ordering positions")
//                        self.fetchLikedHomes() //this refreshes the data
//                    }
//                }
//            }
//    }
//
    
    
    //For the newly added liked homes..we are ensuring that houses are saved with the proper ordering position
    //We are assigning the newly added home to the next available "orderingPos" on the list
    func addNewLikedHome(homeInfo: [String: Any]) {
        guard let userID = Auth.auth().currentUser?.uid,
              let propertyID = homeInfo["propertyID"] as? String
        else {
            print("Missing userID or propertyID")
            return
        }
        
        let newPosition = likedHomes.count
        var homeInfo = homeInfo
        homeInfo["orderingPos"] = newPosition
        
        
        Firestore.firestore()
            .collection("users").document(userID)
            .collection("likedHomes")
            .document(propertyID)
            .setData (homeInfo) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    print("Successfully added new home at position \(newPosition)")
                    self.fetchLikedHomes() //to refresh the list
                }
            }
    }
    
    
    
    //for saving the new order (#4. Saving to DB)
    private func saveOrderOfLikedHome() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let batch = db.batch()  //used .batch() here as its good for bulk updates (ie. reordering of a list)
        
        for (index, home) in likedHomes.enumerated() {  //used .enumerated as it's good for returning a sequence of pairs(n,x) ->n=idex, x=elemenent
            let UserData = db.collection("users").document(userID)
                .collection("likedHomes").document(home.id)
            batch.updateData(["orderingPos": index], forDocument: UserData)
        }
        
        
        batch.commit { error in
            if let error = error {
                print("Error when saving order: \(error.localizedDescription)")

            }else{
                print("Order saved successfully")
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
