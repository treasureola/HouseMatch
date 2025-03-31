//New integration part - Frontend !!

//
//  WelcomeView.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 9/24/24.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftUI

let db = Firestore.firestore()

//This is the front page/Welcome page of the application
struct WelcomeView: View {
    
    @State private var firstName = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationView {
            VStack {  //stacking elements vertically

                Text("Welcome to")
                    .font(.largeTitle)

                Spacer()
                    .bold()
                    .font(.largeTitle)
                Image(.houseA)  //HouseMatch logo
                    .cornerRadius(50)
                    .imageScale(.large)
                    .foregroundStyle(.blue)
                Text("HouseMatch!")
                    .bold()
                    .font(.largeTitle)

                Spacer()
                //The get Started button
                NavigationLink(destination: LoginScreenView(username: firstName, theEmail: email, thePassword: password)) {
                    Text("Get Started")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 5)
                        .background(Color.blue)
                        .cornerRadius(15)

                }
            }
            .padding(.top, 5)
        }
    }
}


//the login page's view
struct LoginScreenView: View {
    @EnvironmentObject var userInfo: UserInfo
    
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    @State private var errorMessage = ""
    
    let username: String
    let theEmail: String
    let thePassword: String
    
    
    let db = Firestore.firestore()
    
    func areLoginInputsValid() -> Bool {
        return !loginEmail.isEmpty && !loginPassword.isEmpty
    }
    
    var body: some View {
        VStack {
            Text("Welcome back!")  //this displays "Welcome back with the user's first name
                .font(.largeTitle)
                .bold()
            
            Text("Login Here")
                .font(.title2)
                .padding(.top, 50)
            Spacer()
            
            TextField("Email", text: $loginEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.top, 10)
                .padding(.horizontal)
            
            SecureField("Password", text: $loginPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 10)
                .padding(.horizontal)
            Spacer()
            
            NavigationLink(destination: SignUpTransitionView()){
                Text("Login Here")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 10)
                    .background(areLoginInputsValid() ? Color.purple : Color.gray) //if its invalid the sign-up will be  gray
                    .cornerRadius(15)
            }
            .disabled(!areLoginInputsValid()) //this would disable if inputs are invalid
            .onTapGesture {
                handleLogin()
            }
            
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, 5)
            }
            
            //                Spacer()
            //                // Side-by-side buttons
            //                HStack {
            //                    NavigationLink(destination: SwipeablePropertiesView()) {
            //                        Text("View Properties")
            //                            .frame(width: 150, height: 20)
            //                            .padding(.top, 5)
            //                            .background(
            //                                areLoginInputsValid() ? Color.blue : Color.gray
            //                            )
            //                            .foregroundColor(.white)
            //                            .cornerRadius(8)
            //                    }
            //                    .disabled(!areLoginInputsValid())
            //                    .onTapGesture {
            //                        handleLogin()
            //                    }
            //                    NavigationLink(destination: FindDreamHome()) {
            //                        Text("Make Preferences")
            //                            .frame(width: 150, height: 20)
            //                            .padding(.top, 5)
            //                            .background(
            //                                areLoginInputsValid() ? Color.green : Color.gray
            //                            )
            //                            .foregroundColor(.white)
            //                            .cornerRadius(8)
            //                    }
            //                    .disabled(!areLoginInputsValid())
            //                }
            //                .navigationTitle("Login")
            //            }
            HStack{
                Text("Don't have an account?")
                NavigationLink(destination: SignUpView()){
                    Text("Sign Up")
                        .foregroundColor(.blue)
                }
            }
            .navigationTitle("Login")
        }
    }
    
    func handleLogin() {
        Auth.auth().signIn(withEmail: loginEmail, password: loginPassword) {
            result, error in
            if let error = error {
                errorMessage = "Login failed: \(error.localizedDescription)"
            } else {
                //successful
                let uid = result?.user.uid
                let userDoc = db.collection("users").document(uid!)
                userDoc.getDocument { (document, error) in
                   if let document = document, document.exists, let userData = document.data() {
                       DispatchQueue.main.async {
                           userInfo.firstName = userData["first_name"] as? String ?? ""
                           userInfo.lastName = userData["last_name"] as? String ?? ""
                           userInfo.email = userData["email"] as? String ?? ""
                       }
                   } else {
                       print("User document does not exist or error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                   }
               }
            }
        }
    }
}


//This is the view you see when you press "Get Started".
//The Sign Up page
struct SignUpView: View {
    @EnvironmentObject var userInfo: UserInfo
    
    @State private var password = ""
    @State private var confirmPassword = ""
    
    //Error states
    @State private var firstNameError = ""
    @State private var lastNameError = ""
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    
    //firebase instance
    let db = Firestore.firestore()
    
    var body: some View {
        VStack(alignment: .center) {
            
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            Text("Create your account")
                .font(.subheadline)
            
            Spacer()
            
            //First name
            TextField("First Name", text: $userInfo.firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            if !firstNameError.isEmpty {
                Text(firstNameError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            //Last Name
            TextField("Last Name", text: $userInfo.lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            if !lastNameError.isEmpty {  //Was newly added
                Text(lastNameError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            //Email
            TextField("Email", text: $userInfo.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.top, 6)
                .padding(.horizontal)
            
            if !emailError.isEmpty {  //Was newly added
                Text(emailError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            //Password
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            if !passwordError.isEmpty {  //Was newly added
                Text(passwordError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            //Confirm Password
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            if !confirmPasswordError.isEmpty {  //Was newly added
                Text(confirmPasswordError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            Spacer()
            Button(action: handlingSignUp) {
                NavigationLink(destination: LoginScreenView(username:  userInfo.firstName, theEmail: userInfo.email, thePassword: password)){
                    Text("Sign up")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.top, 5)
                        .frame(maxWidth: .infinity)
                    //                        .frame(width: 150, height: 20)
                        .background(areInputsValid() ? Color.purple : Color.gray) //if its invalid the sign-up will be  gray
                        .cornerRadius(20)
                        .padding(.horizontal)
                }
                .disabled(!areInputsValid()) //this would disable if inputs are invalid
                .padding(.top, 30)
            }
            
            .padding(.top, 5)
            
            .navigationTitle("Sign up Page")
        }
    }
    // Frontend for BACKEND IMPLEMENTATION START : ISSOUF //
    // THis functionality will handle the connection to the server and the double auth for our users loggin into our application. it also allows for routing and scaling within our vapor backend framework
    func registerUser(email: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "http://ec2-54-161-213-117.compute-1.amazonaws.com:8080/register") else {
            print("Invalid backend URL")
            completion(false, "Invalid backend URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                completion(false, "No response from server")
                return
            }
            
            if httpResponse.statusCode == 200 {
                completion(true, "User registered successfully")
            } else {
                let responseMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                completion(false, responseMessage)
            }
        }.resume()
    }
    // Frontend for BACKEND IMPLEMENTATION END : ISSOUF  //
    
    
    //Making sure that all the inputs aren't empty and that
    //password matches confirmpassword
    func areInputsValid() -> Bool {
        return !userInfo.firstName.isEmpty && !userInfo.lastName.isEmpty && !userInfo.email.isEmpty
        && !password.isEmpty && password == confirmPassword
    }
    
    // Field-specific validation        //Was newly added
    func validateFirstName() {
        firstNameError = userInfo.firstName.isEmpty ? "First name cannot be empty." : ""
    }
    
    func validateLastName() {
        lastNameError = userInfo.lastName.isEmpty ? "Last name cannot be empty." : ""
    }
    
    func validateEmail() {
        if userInfo.email.isEmpty {
            emailError = "Email cannot be empty."
        } else if !userInfo.email.contains("@") {
            emailError = "Please enter a valid email address."
        } else {
            emailError = ""
        }
    }
    
    func validatePassword() {
        passwordError = password.isEmpty ? "Password cannot be empty." : ""
    }
    
    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password."
        } else if password != confirmPassword {
            confirmPasswordError = "Passwords do not match."
        } else {
            confirmPasswordError = ""
        }
    }
    
    func handlingSignUp() {
        print("In Handling Sign Up")
        
        // Clear old errors
        firstNameError = ""
        lastNameError = ""
        emailError = ""
        passwordError = ""
        confirmPasswordError = ""
        
        // Re-validate all fields on sign-up attempt
        validateFirstName()
        validateLastName()
        validateEmail()
        validatePassword()
        validateConfirmPassword()
        
        if areInputsValid() {
            Auth.auth().createUser(withEmail: userInfo.email, password: password) { authResult, error in
                if let error = error {
                    print("Error creating user: \(error.localizedDescription)")
                    // Frontend for BACKEND IMPLEMENTATION Start : ISSOUF  //
                    
                } else if let user = authResult?.user {
                    print("User created successfully! UID: \(user.uid)")
                    
                    let uid = user.uid
                    let userDoc = db.collection("users").document(uid)
                    let userData: [String: Any] = [
                        "first_name": userInfo.firstName,
                        "last_name": userInfo.lastName,
                        "email": userInfo.email,
                    ]
                    
                    userDoc.setData(userData) { error in
                        if let error = error {
                            print("Firestore error: \(error.localizedDescription)")
                        } else {
                            print("User saved in Firestore successfully!")
                            
                            // Register user on your backend too!
                            registerUser(email: userInfo.email) { success, message in
                                if success {
                                    print("Backend registration successful: \(message)")
                                } else {
                                    print("Backend registration failed: \(message)")
                                }
                            }
                            // Frontend for BACKEND IMPLEMENTATION END : ISSOUF  //
                            
                        }
                    }
                }
            }
        } else {
            print("Validation failed. Please correct errors.")
            return
        }
    }
    
    //the sign-up page's view
    struct SignUpTransitionView: View {
        @State private var successfulTransition = true
        @State private var welcomeTransition = true
        @State private var aboutUs = false
        @State private var displayTabView = false
        
        
        var body: some View {
            ZStack {
                VStack {
                    if successfulTransition{
                        Text("Sign up was successful!")
                            .transition(.opacity) //the animation
                    }
                    Spacer()
                    
                    if welcomeTransition{
                        Text("Welcome to HouseMatch!")
                            .font(.title)
                            .transition(.opacity) //the animation
                    }
                    
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Welcome")
                if displayTabView {
                    VStack{
                        Spacer()
                        TabView {
                            Homepage()
                                .tabItem {
                                    Image(systemName: "house.fill")
                                    Text("Houses")
                                }
                            Profile()
                                .tabItem {
                                    Image(systemName: "person.2.fill")
                                    Text("Profile")
                                }
                            Preferences()
                                .tabItem {
                                    Image(systemName: "slider.horizontal.3")
                                    Text("Preferences")
                                }
                        }
                    }
                }
            }
            .onAppear{
                //                 Animation: "Sign Up Successful!" fades away after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        successfulTransition = false
                    }
                }
                // Animation: "Welcome to HouseMatch!" fades away after 6 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        welcomeTransition = false
                    }
                }
                //Animation: this will show the "About Us" right after "Welcome to HouseMatch!" fades away
                DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                    withAnimation {
                        //                        aboutUs = true
                        displayTabView = true
                    }
                }
                
            }
        }
    }
    
    //The view for user/client to make House preferences/choices
    struct FindDreamHome: View {
        @State private var address = "Select Location"
        @State private var property_type = "Select Property Type"
        @State private var price = "Select Price Range"
        @State private var number_Of_Bedrooms = "Select Number of Bedrooms"
        @State private var number_Of_Bathrooms =
        "Select Number of Bathrooms"
        @State private var number_Of_SquareFeet =
        "Select Number of Square Feet"
        
        let locations =
        ["Select Location"] + [
            "Washington, D.C.",
            "New York City",
            "Los Angeles",
            "Boston",
            "Chicago",
            "Houston",
            "Philadelphia",
            "San Francisco",
            "Denver",
            "Salt Lake City",
            "Phoenix",
            "Atlanta",
            "Miami",
        ]
        
        let propertyType =
        ["Select Property Type"] + [
            "Single Family Home", "Condo", "Townhouse", "Apartment",
            "Land", "Multi-Family Home",
        ]
        
        let priceRange =
        ["Select Price Range"] + [
            "$500 - $1000", "$1000 - $1500", "$1500 - $2000",
            "$2000 - $2500", "$2500 - $3000", "$3000 - $3500",
            "$3500 - $4000", "$4000 - $4500", "$4500 - $5000",
        ]
        
        //using Array(1..6) = creates an array with integers from 1 to 6
        //map {"\($0)"} = this maps the integers to its string representation
        let numberOfBedrooms =
        ["Select Number of Bedrooms"] + Array(1...6).map { "\($0)" }
        
        let numberOfBathrooms =
        ["Select Number of Bathrooms"] + Array(1...6).map { "\($0)" }
        
        let numberOfSquareFeet =
        ["Select Number of Square Feet"] + [
            "500+", "600+", "700+", "800+", "900+", "1000+", "1200+",
            "1500+", "2000+", "2500+", "3000+", "3500+", "4000+",
            "5000+", "6000+",
        ]
        
        var body: some View {
            VStack(alignment: .center, spacing: 20) {
                Text("Personalize Your Dream Home!")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                Spacer()
                
                //For the location/Address
                HStack {
                    Text("Location")
                        .padding(.top, 8)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Location", selection: $address) {
                        ForEach(Array(Set(locations)), id: \.self) {
                            location in
                            Text(location)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                
                //For the property type
                HStack {
                    Text("Building Type")
                        .padding(.top, 8)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Property Type", selection: $property_type) {
                        ForEach(propertyType, id: \.self) { property in
                            Text(property)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                
                //For price range
                HStack {
                    Text("Price Range")
                        .padding(.top, 7)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Price Range", selection: $price) {
                        ForEach(priceRange, id: \.self) { price in
                            Text(price)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                
                //For number of Bedrooms
                HStack {
                    Text("Number of Bedrooms")
                        .padding(.top, 20)
                        .padding(.horizontal)
                    Spacer()
                    Picker(
                        "Number of Bedrooms", selection: $number_Of_Bedrooms
                    ) {
                        ForEach(numberOfBedrooms, id: \.self) { number in
                            Text(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                
                HStack {
                    Text("Number of Bathrooms")
                        .padding(.top, 20)
                        .padding(.horizontal)
                    Spacer()
                    Picker(
                        "Number of Bathrooms",
                        selection: $number_Of_Bathrooms
                    ) {
                        ForEach(numberOfBathrooms, id: \.self) { number in
                            Text(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                
                HStack {
                    Text("Number of SquareFootage")
                        .padding(.top, 20)
                        .padding(.horizontal)
                    Spacer()
                    Picker(
                        "Number of SquareFootage",
                        selection: $number_Of_SquareFeet
                    ) {
                        ForEach(numberOfSquareFeet, id: \.self) { number in
                            Text(number)
                            
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                }
                
                Spacer()
                
                //Redirects to the confirmation page
                //It takes in the user preferences from "FindDreamHome" such as (address, property_type, price,number_Of_Bedrooms,number_Of_Bathrooms, number_Of_SquareFeet)
                NavigationLink(
                    destination: ConfirmationPage(
                        
                        address: address,
                        propertyType: property_type,
                        price: price,
                        bedrooms: number_Of_Bedrooms,
                        bathrooms: number_Of_Bathrooms,
                        squareFeet: number_Of_SquareFeet
                    )
                ) {
                    
                    Text("Thank you for designing your dream home!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 5)
                        .background(
                            arePreferencesValid() ? Color.blue : Color.gray
                        )
                        .cornerRadius(10)
                }
                
                .disabled(!arePreferencesValid())  //disables the link if arePreferencesValid() is invalid
                .padding(.top, 20)
                
                .padding(.top, 5)
                .navigationTitle("Dream Home")
            }
        }
        //a function to check that all the inputs aren't empty and a selection has been made
        func arePreferencesValid() -> Bool {
            return address != "Select Location"
            && property_type != "Select Property Type"
            && price != "Select Price Range"
            && number_Of_Bedrooms != "Select Number of Bedrooms"
            && number_Of_Bathrooms != "Select Number of Bathrooms"
            && number_Of_SquareFeet != "Select Number of Square Feet"
        }
    }
    
    //this is the confirmation page after the user/client makes their preferences
    struct ConfirmationPage: View {
        var address: String
        var propertyType: String
        var price: String
        var bedrooms: String
        var bathrooms: String
        var squareFeet: String
        
        let db = Firestore.firestore()
        
        @State private var navigateToProperties = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 20) {
                Text("This is a Confirmation of Your Preferences")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                
                Spacer()
                
                //This take in the inputs made from the FindDreeamHome Page and displays it on the confirmation page.
                Text("Location: \(address)")
                Text("Property Type: \(propertyType)")
                Text("Price Range: \(price)")
                Text("Number of Bedrooms: \(bedrooms)")
                Text("Number of Bathrooms: \(bathrooms)")
                Text("Square Footage: \(squareFeet)")
                
                Spacer()
                
                Button(action: {
                    fetchPropertiesAndStore()
                    navigateToProperties = true  //Triggers NavigationLink
                }) {
                    Text("View Properties")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                }
                
                //NavigationLink is outside the button and controlled by `navigateToProperties`
                NavigationLink(
                    destination: SwipeablePropertiesView(),
                    isActive: $navigateToProperties
                ) {
                    EmptyView()  //Invisible link
                }
            }
            .padding(.top, 5)
            .navigationTitle("Confirmation")
        }
        
        func savePreferences() {
            guard let userID = Auth.auth().currentUser?.uid else {
                print("Error: No authenticated user found.")
                return
            }
            let (minPrice, maxPrice) = parsePriceRange(price)
            let cleanSquareFeet = squareFeet.replacingOccurrences(of: "+", with: "")
            let userDoc = db.collection("users").document(userID)
            let preferences: [String: Any] = [
                "location": address,
                "propertyType": propertyType,
                "minPrice": minPrice,
                "maxPrice": maxPrice,
                "bedrooms": bedrooms,
                "bathrooms": bathrooms,
                "squareFeet": cleanSquareFeet,
                "timestamp": Timestamp(),
            ]
            
            userDoc.setData(["preferences": preferences], merge: true) {
                error in
                if let error = error {
                    print(
                        "Error saving preferences: \(error.localizedDescription)"
                    )
                } else {
                    print("Preferences saved successfully")
                    navigateToProperties = true
                }
            }
        }
        
        func parsePriceRange(_ range: String) -> (Any, Any) {
            let numbers = range.components(
                separatedBy: CharacterSet.decimalDigits.inverted
            )
                .compactMap { Int($0) }
            return (numbers[0], numbers[1])
        }
        
        
        func fetchPropertiesAndStore() {
            print("Fetching Properties")
            
            guard let userID = Auth.auth().currentUser?.uid else {
                print("Error: No authenticated user found.")
                return
            }
            
            let db = Firestore.firestore()
            let userDoc = db.collection("users").document(userID)
            
            userDoc.getDocument { (document, error) in
                if let error = error {
                    print("Error fetching user preferences: \(error.localizedDescription)")
                    return
                }
                
                guard let document = document, document.exists,
                      let userPreferences = document.data()?["preferences"] as? [String: Any] else {
                    print("No preferences found for user.")
                    return
                }
                
                guard let location = userPreferences["location"] as? String else {
                    print("Error: Missing or invalid user preferences.")
                    return
                }
                
                let propertiesCollection = db.collection("properties")
                propertiesCollection.whereField("assignedUserID", isEqualTo: userID)
                    .whereField("viewed", isEqualTo: false)
                    .getDocuments { (snapshot, error) in
                        if let error = error {
                            print("Error checking existing properties: \(error.localizedDescription)")
                            return
                        }
                        
                        let existingUnviewedCount = snapshot?.documents.count ?? 0
                        if existingUnviewedCount >= 50 {
                            print("User already has 50 unviewed properties, skipping fetch.")
                            return
                        }
                        
                        fetchFromAPI(userPreferences: userPreferences, userID: userID, db: db)
                    }
            }
        }
        
        func fetchFromAPI(userPreferences: [String: Any], userID: String, db: Firestore) {
            
            guard let location = userPreferences["location"] as? String,
                  let maxPrice = userPreferences["maxPrice"] as? Int,
                  let bedrooms = userPreferences["bedrooms"] as? String,
                  let bathrooms = userPreferences["bathrooms"] as? String else {
                print("Error: Missing or invalid user preferences.")
                return
            }
            
            
            // Format query parameters based on user preferences
            let formattedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
            let urlString = "https://realtor-search.p.rapidapi.com/properties/search-rent?location=city:\(formattedLocation)&price_max=\(maxPrice)&beds_min=\(bedrooms)&baths_min=\(bathrooms)&resultsPerPage=100&sortBy=best_match"
            
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("41074491b8msh897384f5dfbdfd4p122b3cjsn3bf3b6b434f6", forHTTPHeaderField: "x-rapidapi-key")
            request.setValue("realtor-search.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
            
            let session = URLSession.shared
            let dataTask = session.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error fetching properties: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    guard let results = json?["data"] as? [String: Any],
                          let properties = results["results"] as? [[String: Any]] else {
                        print("Invalid response format")
                        return
                    }
                    
                    let db = Firestore.firestore()
                    let propertiesCollection = db.collection("properties")
                    
                    for property in properties {
                        
                        let categories = ((property["details"] as? [[String: Any]])?.compactMap { $0["text"] as? [String] }.flatMap { $0 }) ?? []
                        let sanitizedCategories = categories.map { $0.replacingOccurrences(of: "/", with: "-") }
                        
                        let amenitiesArray = ((property["details"] as? [[String: Any]])?
                            .compactMap { $0["text"] as? [String] }
                            .flatMap { $0 }
                        ) ?? []
                        
                        
                        let propertyData: [String: Any] = [
                            "property_id": property["property_id"] as? String ?? "",
                            "listing_id": property["listing_id"] ?? "",
                            "status": property["status"] ?? "Unknown",
                            "photo_url": (property["primary_photo"] as? [String: Any])?["href"] ?? "",
                            "address": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["line"] as? String ?? "",
                            "city": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["city"] ?? "",
                            "state_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["state_code"] ?? "",
                            "postal_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["postal_code"] ?? "",
                            "price": property["list_price_max"] ?? 0,
                            "bedrooms": (property["description"] as? [String: Any])?["beds_max"] ?? 0,
                            "bathrooms": (property["description"] as? [String: Any])?["baths_max"] ?? 0,
                            "square_feet": (property["description"] as? [String: Any])?["sqft_max"] ?? 0,
                            "listing_url": property["href"] ?? "",
                            "amenities": amenitiesArray,
                            "petFriendly": property["pet_policy.cats"] as? Bool == true || property["pet_policy.dogs"] as? Bool == true,
                            "assignedUserID": userID,
                            "viewed": false
                        ]
                        
                        // Saves the property data to Firestore
                        propertiesCollection.addDocument(data: propertyData) { error in
                            if let error = error {
                                print("Error saving property to Firestore: \(error.localizedDescription)")
                            } else {
                                print("Property successfully saved!")
                            }
                        }
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }
            
            dataTask.resume()
        }
    }
    
    struct ThankYouPage: View {
        var body: some View {
            VStack {
                Text(
                    "Thank you. Your housing preferences have been saved"
                )
                .font(.largeTitle)
                .padding(.bottom, 20)
            }
            .navigationTitle("Thank You")
            
        }
    }
    
    
    
    
    
    //                //a property struct to hold the building data
    //                //we use hasable becuase we use 'Property struct' as the identifier in the ForEach loop
    //                struct Property: Hashable {
    //                    var typeOfBuilding: String
    //                    var imageName: String
    //                    var description: String
    //                }
    
    
    
    //                struct PropertiesAndBuildingsSwipe: View {
    //                    // an array of Property instances with title, image, and description
    //                    private var properties: [Property] = [
    //                        Property(
    //                            typeOfBuilding: "Single Family Home",
    //                            imageName: "singleFamily_House",
    //                            description: "A detached, single-family property"),
    //                        Property(
    //                            typeOfBuilding: "Condo", imageName: "Condo11",
    //                            description:
    //                                "A single unit in a condominium development or building, part of a homeowner’s association (HOA)"
    //                        ),
    //                        Property(
    //                            typeOfBuilding: "Townhouse",
    //                            imageName: "TownHouse1",
    //                            description:
    //                                "A single-family property that shares walls with other adjacent homes, part of a homeowner’s association (HOA)"
    //                        ),
    //                        Property(
    //                            typeOfBuilding: "Apartment",
    //                            imageName: "apartment-building",
    //                            description:
    //                                "A rental unit within a multi-unit building"),
    //                        Property(
    //                            typeOfBuilding: "Land", imageName: "Plot_of_land",
    //                            description: "An empty plot of land"),
    //                        Property(
    //                            typeOfBuilding: "Multi-Family Home",
    //                            imageName: "Multi-Family_Home",
    //                            description:
    //                                "A residential multi-family building (2-4 units)"
    //                        ),
    //                    ].reversed()  // Optional: reversing the order if needed
    //
    //                    var body: some View {
    //                        VStack {
    //                            ZStack {
    //                                ForEach(properties, id: \.self) { property in
    //                                    propertyCardView(
    //                                        typeOfBuilding: property.typeOfBuilding,
    //                                        imageName: property.imageName,
    //                                        description: property.description
    //                                    )
    //
    //                                }
    //                            }
    //                        }
    //                    }
    //                }
    
    #Preview {
        WelcomeView()
    }
    
    
    
    // ISSOUF CODE BELOW DISREGARD AS I AM INTEGRATING
}
    

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

//
//// User Login (Firebase Authentication)
//app.post("login") { req async throws -> TokenResponse in
//    let loginInput = try req.content.decode(UserInput.self)
//
//    // Ensure the token is not nil and not empty
//    guard let firebaseToken = loginInput.token, !firebaseToken.isEmpty else {
//        throw Abort(.unauthorized, reason: "Missing Firebase token")
//    }
//
//    let verifiedUser = try await FirebaseAuthService.verifyToken(firebaseToken)
//
//    // Check if the user exists in the database
//    guard let user = try await User.query(on: req.db)
//        .filter(\.$email == verifiedUser.email)
//        .first() else {
//        throw Abort(.unauthorized, reason: "User not found. Please register before logging in.")
//    }
//
//    print("User exists, logging in: \(user.email)")
//
//    // Return a token response to the frontend
//    return TokenResponse(token: firebaseToken)
//}

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
