//
//  UserInfo.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 2/16/25.
//

//
//  UserInfo.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 2/15/25.
//

import SwiftUI

//1N. We created a class called "UserInfo" for the shared data model
// We also used "@Published" as a way to automatically notify any observing views when either the first or last name, or email changes.

class UserInfo: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var email: String = ""
    @Published var hasPreferences: Bool = false
    
    @AppStorage("isNewUser") var isNewUser: Bool = true
    @AppStorage("initialSwipeCount") var initialSwipeCount: Int = 0
    
    let maxInitialSwipes = 20
    
    func recordSwipeForNewUser() {
        if isNewUser && initialSwipeCount < maxInitialSwipes {
            initialSwipeCount += 1
            if initialSwipeCount >= maxInitialSwipes {
                isNewUser = false
                print("User has completed initial swipes and is now a regular user.")
            }
             print("Initial swipe count: \(initialSwipeCount)")
        }
    }
    
    func clear(){
        firstName = ""
        lastName = ""
        email = ""
        hasPreferences = false
    }
}
