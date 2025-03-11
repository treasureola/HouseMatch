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

@main
struct Simple_GUIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userInfo = UserInfo()
    
    var body: some Scene {
        WindowGroup {
           WelcomeView()
                .environmentObject(userInfo)
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
