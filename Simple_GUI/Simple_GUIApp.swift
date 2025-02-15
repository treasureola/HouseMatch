//
//  Simple_GUIApp.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 9/24/24.
//

import SwiftUI

@main
struct Simple_GUIApp: App {
    
    //2N. this creates an instance of the UserNames
    //@StateObject is used for creating and managing a reference type (UserInfo)
    //Basically the 'UserInfo' object is created once and will and use throughout the app
    @StateObject private var userInfo = UserInfo()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                //the 'userInfo' object is now available for all the views in the app
                .environmentObject(userInfo)
        }
    }
}
 
