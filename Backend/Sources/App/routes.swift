import Vapor
import Fluent

// NEED TO RESTRUCUTURE THE CODE WHEN I GET A CHANCE

func routes(_ app: Application) throws {
    let protected = app.grouped(FirebaseAuthMiddleware())
    
    //  Protected Route Example
    protected.get("protected") { req async throws -> String in
        let user = try req.auth.require(FirebaseUser.self)
        return "You are authenticated as \(user.email)"
    }
    
    
    // ######################################### FRONTEND USER-REGISTRATION CODE INTEGRATED ######################################################\\\
//    func registerUser(email: String, completion: @escaping (Bool, String) -> Void) {
//        // Have to update if the IPv4 Address continuoulsy decides to change, I hope not
//        guard let url = URL(string: "http://ec2-54-161-213-117.compute-1.amazonaws.com:8080/register")  else {
//            print("Invalid backend URL")
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        let body: [String: String] = ["email": email]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
//                completion(false, "No response from server")
//                return
//            }
//            
//            if httpResponse.statusCode == 200 {
//                completion(true, "User registered successfully")
//            } else {
//                let responseMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
//                completion(false, responseMessage)
//            }
//        }.resume()
//    }
    // ######################################### END OF FRONTEND USER-REGISTRATION CODE INTEGRATED ######################################################\\\
    
    
    // ######################################### BACKEND USER-REGISTRATION CODE INTEGRATED ######################################################\\\
    
    // Backend User Registration Functionality
    app.post("register") { req async throws -> HTTPStatus in
        let userInput = try req.content.decode(UserInput.self)
        
        let newUser = User(email: userInput.email)  // Removed passwordHash
        
        if let _ = try await User.query(on: req.db)
            .filter(\.$email == newUser.email)
            .first() {
            throw Abort(.conflict, reason: "Email already exists")
        }
        
        try await newUser.save(on: req.db)
        return .ok
    }
    // ######################################### END OF BACKEND USER-REGISTRATION CODE INTEGRATED ######################################################\\\
    
    
    // ######################################### FRONTEND LOGIN CODE INTEGRATED ######################################################\\\
    // ISSOUF : Adding the Backend Server to the FrontEnd Code Implementation
    // Note the server I am connecting to is the Vapor Backend Framework. I'll have to add the ML server to the other backend
//    func loginUser(email: String, firebaseToken: String, completion: @escaping (Bool, String) -> Void) {
//        guard let url = URL(string: "http://ec2-54-161-213-117.compute-1.amazonaws.com:8080/login") else {
//            print("Invalid backend URL")
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body: [String: String] = ["email": email, "token": firebaseToken]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
//                completion(false, "No response from server")
//                return
//            }
//
//            if httpResponse.statusCode == 200 {
//                completion(true, "User logged in successfully")
//            } else if httpResponse.statusCode == 401 {
//                completion(false, "User not found. Please register before logging in.")
//            } else {
//                let responseMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
//                completion(false, responseMessage)
//            }
//        }.resume()
//    }
//
//    
//    func handlingSignUp() {
//        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
//            if let error = error {
//                print("Error creating user: \(error.localizedDescription)")
//            } else if let user = authResult?.user {
//                print("User created successfully! UID: \(user.uid)")
//                
//                user.getIDToken { idToken, error in
//                    if let idToken = idToken {
//                        // Send token to backend
//                        loginUser(email: user.email ?? "", token: idToken) { success, message in
//                            DispatchQueue.main.async {
//                                if success {
//                                    print(" Login Successful: \(message)")
//                                } else {
//                                    print(" Login Failed: \(message)")
//                                }
//                            }
//                        }
//                    } else {
//                        print(" Failed to retrieve Firebase token")
//                    }
//                }
//            }
//        }
//    }
//    
    
    // ######################################### END OF FRONTEND LOGIN CODE INTEGRATED ######################################################\\\
    
    //    When a user logs in, Firebase first authenticates them and generates an ID token. The frontend then sends this ID token to the backend, where it is verified with Firebase to confirm its validity.
    //    Once verified, the backend checks if the user already exists in the database. If the user exists, they are successfully logged in. If the user does not exist, they are automatically registered in the database and then logged in.
    //    After authentication, the backend sends a session token back to the frontend, allowing the user to maintain their session securely. This process ensures a seamless and secure authentication flow, integrating Firebase authentication with the Vapor backend.
    
    // #########################################   BACKEND LOGIN CODE INTEGRATED ######################################################\\\
    
    
    // User Login (Firebase Authentication)
    app.post("login") { req async throws -> TokenResponse in
        let loginInput = try req.content.decode(UserInput.self)

        // Ensure the token is not nil and not empty
        guard let firebaseToken = loginInput.token, !firebaseToken.isEmpty else {
            throw Abort(.unauthorized, reason: "Missing Firebase token")
        }

        let verifiedUser = try await FirebaseAuthService.verifyToken(firebaseToken)

        // Check if the user exists in the database
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == verifiedUser.email)
            .first() else {
            throw Abort(.unauthorized, reason: "User not found. Please register before logging in.")
        }

        print("User exists, logging in: \(user.email)")

        // Return a token response to the frontend
        return TokenResponse(token: firebaseToken)
    }

    // ######################################### END OF BACKEND LOGIN CODE INTEGRATED ######################################################\\\
    
    // ######################################### FRONTEND  PREFERENCES CODE INTEGRATED ######################################################\\\
//    func savePreferences() {
//    guard let userID = Auth.auth().currentUser?.uid else {
//        print("Error: No authenticated user found.")
//        return
//    }
//
//    guard let url = URL(string: "http://ec2-54-161-213-117.compute-1.amazonaws.com:8080/login") else {
//            print("Invalid backend URL")
//            return
//        }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//    let preferences: [String: Any] = [
//        "location": address,
//        "propertyType": property_type,
//        "minPrice": minPrice,
//        "maxPrice": maxPrice,
//        "bedrooms": number_Of_Bedrooms,
//        "bathrooms": number_Of_Bathrooms,
//        "squareFeet": number_Of_SquareFeet
//    ]
//
//    request.httpBody = try? JSONSerialization.data(withJSONObject: preferences)
//
//    URLSession.shared.dataTask(with: request) { data, response, error in
//        guard let data = data, let httpResponse = response as? HTTPURLResponse else {
//            print("No response from server")
//            return
//        }
//
//        if httpResponse.statusCode == 200 {
//            print("Preferences saved successfully")
//        } else {
//            let responseMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
//            print("Failed to save preferences: \(responseMessage)")
//        }
//    }.resume()
//}
    // ######################################### END OF FRONTEND PREFERENCES CODE INTEGRATED ######################################################\\\

    // ######################################### BACKEND PREFERENCES CODE INTEGRATED ######################################################\\\

app.group("preferences") { preferences in
    // GET: Retrieve user preferences
    preferences.get { req async throws -> UserPreference in
        let user = try req.auth.require(User.self)

        guard let preference = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .first() else {
            throw Abort(.notFound, reason: "Preferences not found")
        }

        return preference
    }

    // POST: Save or update user preferences
    preferences.post { req async throws -> HTTPStatus in
        let user = try req.auth.require(User.self)
        let newPreference = try req.content.decode(UserPreference.self)

        if let existingPreference = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .first() {
            // Update existing preferences
            existingPreference.location = newPreference.location
            existingPreference.propertyType = newPreference.propertyType
            existingPreference.minPrice = newPreference.minPrice
            existingPreference.maxPrice = newPreference.maxPrice
            existingPreference.bedrooms = newPreference.bedrooms
            existingPreference.bathrooms = newPreference.bathrooms
            existingPreference.squareFeet = newPreference.squareFeet
            try await existingPreference.save(on: req.db)
            return .ok
        } else {
            // Create new preferences
            let userPreference = UserPreference(
                userID: try user.requireID(),
                location: newPreference.location,
                propertyType: newPreference.propertyType,
                minPrice: newPreference.minPrice,
                maxPrice: newPreference.maxPrice,
                bedrooms: newPreference.bedrooms,
                bathrooms: newPreference.bathrooms,
                squareFeet: newPreference.squareFeet
            )
            try await userPreference.save(on: req.db)
            return .created
        }
    }
}
 // ######################################### END OF BACKEND PREFERENCES CODE INTEGRATED ######################################################\\\


// ######################################### FRONTEND FILTER-PREFERENCES CODE INTEGRATED ######################################################\\\
//func fetchMatchingProperties() {
//    guard let url = URL(string: "http://ec2-54-161-213-117.compute-1.amazonaws.com:8080/login") else {
//            print("Invalid backend URL")
//            return
//        }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "GET"
//    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//    URLSession.shared.dataTask(with: request) { data, response, error in
//        guard let data = data else {
//            print("No data received")
//            return
//        }
//
//        do {
//            let properties = try JSONDecoder().decode([Property].self, from: data)
//            DispatchQueue.main.async {
//                self.properties = properties
//            }
//        } catch {
//            print("Error decoding JSON: \(error.localizedDescription)")
//        }
//    }.resume()
//}


// ######################################### END OF FRONTEND FILTER-PREFERENCES CODE INTEGRATED ######################################################\\\

// ######################################### BACKEND VIEW PROPERTIES CODE INTEGRATED ######################################################\\\
    // GET: Fetch properties based on user preferences
    protected.get("match-properties") { req async throws -> [Property] in
        let user = try req.auth.require(User.self)

        // Get user preferences
        guard let preference = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .first() else {
            throw Abort(.notFound, reason: "No preferences found for this user.")
        }

    // Convert Integer preferences to Double for correct filtering
    // Using _ = tells Swift that we are intentionally ignoring these values.

    _ = Double(preference.minPrice)
    _ = Double(preference.maxPrice)
    _ = Double(preference.squareFeet)

    // Query properties that match user preferences
    let filteredProperties = try await Property.query(on: req.db)
        .filter(\.$city == preference.location)
        .filter(\.$propertyType == preference.propertyType)
        .filter(\.$price >= Int(preference.minPrice))
        .filter(\.$price <= Int(preference.maxPrice))
        .filter(\.$bedrooms >= preference.bedrooms)
        .filter(\.$bathrooms >= preference.bathrooms)
        .filter(\Property.$squareFeet >= Int(preference.squareFeet))
        .all()

    return filteredProperties
}

// ######################################### END OF BACKEND VIEW PROPERTIES CODE INTEGRATED ######################################################\\\


}
