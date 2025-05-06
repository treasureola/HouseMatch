//
//  AppEntryView.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 4/10/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AppEntryView: View {
    @StateObject var userInfo = UserInfo() // already shared in your environment
    @State private var isLoggedIn = false
    @State private var isLoading = true
    @State private var showLogin = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            }
            else if !isLoggedIn {
                // If the user is not logged in, show the welcome/login screen.
                if showLogin {
                    NavigationStack { LoginScreenView() }
                } else {
                    WelcomeView()
                }
            }
            else {
                // User is logged in: check preferences.
                if userInfo.hasPreferences {
                    // Preferences have been set – show the homepage.
                    MainTabView()
                } else {
                    // No preferences have been found – show the Preferences screen.
//                    Preferences()
                    NavigationStack { FindDreamHome() }
                }
            }
        }
        .onAppear {
            
            showLogin = UserDefaults.standard.bool(forKey: "showLogin")
            
            // Listen to the Firebase Auth state:
            Auth.auth().addStateDidChangeListener { auth, user in
                if let user = user {
                    isLoggedIn = true
                    
                    UserDefaults.standard.removeObject(forKey: "showLogin")
                    showLogin = false
                    
                    fetchUserInfo(uid: user.uid)
                    
                    // Once logged in, check if the user has preferences
                    let db = Firestore.firestore()
                    db.collection("users").document(user.uid).getDocument { document, error in
                        if let document = document,
                            document.exists,
                            let data = document.data() {
                            // Check if preferences exist; adjust the key name accordingly.
                            userInfo.hasPreferences = (data["preferences"] as? [String: Any]) != nil
                        } else {
                            userInfo.hasPreferences = false
                        }
                        // Loading is done once you have the answer.
                        isLoading = false
                    }
                } else {
                    isLoggedIn = false
                    userInfo.clear()
                    showLogin = UserDefaults.standard.bool(forKey: "showLogin")
                    isLoading = false
                }
            }
        }
        .environmentObject(userInfo)
    }
    
    func fetchUserInfo(uid: String) {
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(uid)
        userDoc.getDocument { document, error in
            if let document = document, document.exists, let userData = document.data() {
                DispatchQueue.main.async {
                    userInfo.firstName = userData["first_name"] as? String ?? ""
                    userInfo.lastName = userData["last_name"] as? String ?? ""
                    userInfo.email = userData["email"] as? String ?? ""
                    print("User info fetched successfully: \(userInfo)")
                }
            } else {
                print("User info not found.")
            }
        }
    }
}
