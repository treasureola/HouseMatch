//
//  Simple_GUIApp.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 9/24/24.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

@main
struct Simple_GUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userInfo = UserInfo()
    @State private var isLoggedIn = false
    
    var body: some Scene {
        WindowGroup {
            Group{
                if isLoggedIn{
                    MainTabView()
                } else{
                    WelcomeView()
                }
            }
            .environmentObject(userInfo)
            .onAppear{
                //listen for change in suthetication state
                Auth.auth().addStateDidChangeListener { auth, user in
                    DispatchQueue.main.async{
                        self.isLoggedIn = (user != nil)
                    }
                    if let user = user {
                        fetchFirestoreUserInfo(uid: user.uid)
                    } else{
                        userInfo.clear()
                    }
                }
            }
        }
    }
    
    func fetchFirestoreUserInfo(uid: String){
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(uid)
        userDoc.getDocument { (document, error) in
            if let document = document, document.exists, let userData = document.data() {
                DispatchQueue.main.async{
                    userInfo.firstName = userData["first_name"] as? String ?? ""
                    userInfo.lastName = userData["last_name"] as? String ?? ""
                    userInfo.email = userData["email"] as? String ?? ""
                    print("User fetched correctly")
                }
            } else {
                print ("User does not exist")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Configured Firebase!")
        return true
    }
}


struct MainTabView: View{
    var body: some View{
        TabView{
            Homepage()
                .tabItem{
                    Image(systemName: "house.fill")
                    Text("Houses")
                }
            Profile()
                .tabItem{
                    Image(systemName: "person.2.fill")
                    Text("Profile")
                }
            Preferences()
                .tabItem{
                    Image(systemName: "slider.horizontal.3")
                    Text("Preferences")
                }
        }
    }
}

