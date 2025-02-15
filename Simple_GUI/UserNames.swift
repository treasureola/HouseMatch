//
//  UserNames.swift
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
}
