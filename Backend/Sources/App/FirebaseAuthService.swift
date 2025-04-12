//
//  FirebaseAuthService.swift
//  Backend_Property_Search
//
//  Created by Issouf Diarrassouba
//

import Vapor

struct FirebaseAuthService {
    static func verifyToken(_ token: String) async throws -> FirebaseUser {
        let firebaseVerificationURL = "https://www.googleapis.com/identitytoolkit/v3/relyingparty/getAccountInfo?key=AIzaSyB8j2TtqyJgaAVRt5BS2wmMw92ghP1HQbQ"

        var firebaseRequest = URLRequest(url: URL(string: firebaseVerificationURL)!)
        firebaseRequest.httpMethod = "POST"
        firebaseRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = ["idToken": token]
        firebaseRequest.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: firebaseRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw Abort(.unauthorized, reason: "Invalid Firebase token")
        }

        let firebaseResponse = try JSONDecoder().decode(FirebaseUserInfo.self, from: data)
        guard let email = firebaseResponse.users.first?.email else {
            throw Abort(.unauthorized, reason: "No email found in Firebase token")
        }

        return FirebaseUser(email: email)
    }
}

struct FirebaseUser: Authenticatable {
    let email: String
}

struct FirebaseUserInfo: Codable {
    let users: [UserInfo]
}

struct UserInfo: Codable {
    let email: String
}
