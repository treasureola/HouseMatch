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
            AppEntryView()
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

