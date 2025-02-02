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
                NavigationLink(destination: SignUpView()) {
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

//This is the view you see when you press "Get Started".
//The Sign Up page
struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
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
            TextField("First Name", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            if !firstNameError.isEmpty {
                Text(firstNameError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            //Last Name
            TextField("Last Name", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            if !lastNameError.isEmpty {  //Was newly added
                Text(lastNameError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            
            //Email
            TextField("Email", text: $email)
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
                Text("Sign up")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.top, 5)
                    .frame(width: 150, height: 20)
                    .background(areInputsValid() ? Color.purple : Color.gray)  //if its invalid the sign-up will be  gray
                    .cornerRadius(20)
                    .padding(.horizontal)
            }
            .disabled(!areInputsValid())  //this would disable if inputs are invalid
            .padding(.top, 30)
        }
        
        //the login page
        HStack {
            Text("Already have an account?")
            NavigationLink(
                destination: LoginScreenView(
                    username: firstName, theEmail: email, thePassword: password)
            ) {
                Text("Login")
                    .foregroundColor(.blue)
            }
            .underline()
        }
        .padding(.top, 5)
        
        .navigationTitle("Sign up Page")
    }
    
    //Making sure that all the inputs aren't empty and that
    //password matches confirmpassword
    func areInputsValid() -> Bool {
        return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty
        && !password.isEmpty && password == confirmPassword
    }
    
    // Field-specific validation        //Was newly added
    func validateFirstName() {
        firstNameError = firstName.isEmpty ? "First name cannot be empty." : ""
    }
    
    func validateLastName() {
        lastNameError = lastName.isEmpty ? "Last name cannot be empty." : ""
    }
    
    func validateEmail() {
        if email.isEmpty {
            emailError = "Email cannot be empty."
        } else if !email.contains("@") {
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
    
    func handlingSignUp() {  //Was newly added
        
        print("In Handling SIgn Up")
        
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
            Auth.auth().createUser(withEmail: email, password: password) {
                authResult, error in
                if let error = error {
                    print("Error creating user: \(error.localizedDescription)")
                } else if let user = authResult?.user {
                    print("User created successfully! UID: \(user.uid)")
                    
                    let uid = user.uid
                    let userDoc = db.collection("users").document(uid)
                    let userData: [String: Any] = [
                        "first_name": firstName,
                        "last_name": lastName,
                        "email": email,
                    ]
                    
                    userDoc.setData(userData) { error in
                        if let error = error {
                            print(
                                "Firestore error: \(error.localizedDescription)"
                            )
                        } else {
                            print("User saved in Firestore successfully!")
                        }
                    }
                }
            }
        } else {
            print("Validation failed. Please correct errors.")
            return
        }
    }
    
    //the login page's view
    struct LoginScreenView: View {
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
                Text("Welcome back, \(username)!")  //this displays "Welcome back with the user's first name
                    .font(.largeTitle)
                    .bold()
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
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }
                
                Spacer()
                // Side-by-side buttons
                HStack {
                    NavigationLink(destination: SwipeablePropertiesView()) {
                        Text("View Properties")
                            .frame(width: 150, height: 20)
                            .padding(.top, 5)
                            .background(
                                areLoginInputsValid() ? Color.blue : Color.gray
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!areLoginInputsValid())
                    .onTapGesture {
                        handleLogin()
                    }
                    NavigationLink(destination: FindDreamHome()) {
                        Text("Make Preferences")
                            .frame(width: 150, height: 20)
                            .padding(.top, 5)
                            .background(
                                areLoginInputsValid() ? Color.green : Color.gray
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!areLoginInputsValid())
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
                        if let document = document, document.exists {
                            let userData = document.data()
                        } else {
                            print("User does not exist")
                            //create front end representation
                        }
                    }
                }
            }
        }
        
        //the sign-up page's view
        struct SignUpTransitionView: View {
            @State private var successfulTransition = true
            @State private var welcomeTransition = true
            @State private var aboutUs = false
            
            var body: some View {
                VStack {
                    if successfulTransition {
                        Text("Sign up was successful!")
                            .transition(.opacity)  //the animation
                    }
                    Spacer()
                    
                    if welcomeTransition {
                        Text("Welcome to HouseMatch!")
                            .font(.title)
                            .transition(.opacity)  //the animation
                    }
                    
                    if aboutUs {
                        Text("About Us")
                        //                    .font(.headline)
                            .font(.largeTitle)
                            .bold()
                            .padding(.top, 5)
                        //                Spacer()
                        
                        Text(
                            "We are an AI-powered platform for matching ideal homes with tenants based on budget, location, preferences, and availability, while also helping landlords find suitable tenants in real time."
                        )
                        .font(.body)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        
                        Spacer()
                        //the link to view the properties available
                        NavigationLink(destination: FindDreamHome()) {
                            
                            Text("Make preferences")
                                .font(.headline)
                                .foregroundColor(.white)
                            //                            .padding(.top, 5)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding(.top, 20)
                        }
                        
                    }
                    Spacer()
                }
                .padding(.top, 5)
                .navigationTitle("Welcome")
                .onAppear {
                    // Animation: "Sign Up Successful!" fades away after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            successfulTransition = false
                        }
                    }
                    // Animation: "Welcome to HouseMatch!" fades away after 6 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        withAnimation {
                            welcomeTransition = false
                        }
                    }
                    //Animation: this will show the "About Us" right after "Welcome to HouseMatch!" fades away
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                        withAnimation {
                            aboutUs = true
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
                        
                        NavigationLink(destination: SwipeablePropertiesView()){
                            Button(action: {
                                savePreferences()
                                fetchPropertiesAndStore()
                            }) {
                                
                                Text("Confirm and Submit")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(.top, 5)
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
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
                        
                        guard let document = document, document.exists, let userPreferences = document.data()?["preferences"] as? [String: Any] else {
                            print("No preferences found for user.")
                            return
                        }
                        
                        guard let location = userPreferences["location"] as? String,
                              let minPrice = userPreferences["minPrice"] as? Int,
                              let maxPrice = userPreferences["maxPrice"] as? Int,
                              let bedrooms = userPreferences["bedrooms"] as? String,
                              let bathrooms = userPreferences["bathrooms"] as? String else {
                            print("Error: Missing or invalid user preferences.")
                            return
                        }
                        
                        // Format query parameters based on user preferences
                        let formattedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
                        let urlString = "https://realtor-search.p.rapidapi.com/properties/search-rent?location=city:\(formattedLocation)&price_min=\(minPrice)&price_max=\(maxPrice)&beds_min=\(bedrooms)&baths_min=\(bathrooms)&sortBy=best_match"
                        
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
                                    let propertyData: [String: Any] = [
                                        "property_id": property["property_id"] ?? UUID().uuidString,
                                        "listing_id": property["listing_id"] ?? "",
                                        "status": property["status"] ?? "Unknown",
                                        "photo_url": (property["primary_photo"] as? [String: Any])?["href"] ?? "",
                                        "address": (property["location"] as? [String: Any])?["address"] as? [String: Any] ?? [:],
                                        "city": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["city"] ?? "",
                                        "state_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["state_code"] ?? "",
                                        "postal_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["postal_code"] ?? "",
                                        "price_min": property["list_price_min"] ?? 0,
                                        "price_max": property["list_price_max"] ?? 0,
                                        "bedrooms_min": (property["description"] as? [String: Any])?["beds_min"] ?? 0,
                                        "bedrooms_max": (property["description"] as? [String: Any])?["beds_max"] ?? 0,
                                        "bathrooms_min": (property["description"] as? [String: Any])?["baths_min"] ?? 0,
                                        "bathrooms_max": (property["description"] as? [String: Any])?["baths_max"] ?? 0,
                                        "square_feet_min": (property["description"] as? [String: Any])?["sqft_min"] ?? 0,
                                        "square_feet_max": (property["description"] as? [String: Any])?["sqft_max"] ?? 0,
                                        "listing_url": property["href"] ?? ""
                                    ]
                                    
                                    propertiesCollection.document("\(propertyData["property_id"]!)").setData(propertyData) { error in
                                        if let error = error {
                                            print("Error saving property: \(error.localizedDescription)")
                                        } else {
                                            print("Property saved successfully!")
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
                
                struct Property: Identifiable {
                    let id: String
                    let imageUrl: String
                    let address: String
                    let price: Int
                    let bedrooms: Int
                    let bathrooms: Int
                    let listingUrl: String
                }
                
                struct PropertyCard: View {
                    let property: Property
                    var onRemove: (() -> Void)? // Callback when card is swiped

                    @State private var offset: CGSize = .zero
                    @State private var color: Color = .white

                    var body: some View {
                        ZStack {
                            VStack {
                                if let imageUrl = URL(string: property.imageUrl) {
                                    AsyncImage(url: imageUrl) { image in
                                        image.resizable()
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(height: 300)
                                    .cornerRadius(15)
                                }
                                
                                Text(property.address)
                                    .font(.headline)
                                    .padding(.top, 5)

                                Text("$\(property.price)")
                                    .font(.title)
                                    .bold()

                                HStack {
                                    Text("\(property.bedrooms) Beds • \(property.bathrooms) Baths")
                                        .font(.subheadline)
                                }

                                Spacer()

                                // Button to view more details
                                Link("View Listing", destination: URL(string: property.listingUrl)!)
                                    .foregroundColor(.blue)
                                    .padding()
                            }
                            .padding()
                            .background(color)
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .offset(offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        self.offset = gesture.translation
                                        self.color = offset.width > 0 ? .green : .red
                                    }
                                    .onEnded { _ in
                                        if abs(offset.width) > 150 {
                                            onRemove?() // Remove the card if swiped far enough
                                        } else {
                                            offset = .zero
                                            color = .white
                                        }
                                    }
                            )
                        }
                    }
                }
                
                class PropertyViewModel: ObservableObject {
                    @Published var properties: [Property] = []

                    func fetchProperties() {
                        let db = Firestore.firestore()
                        db.collection("properties").getDocuments { (snapshot, error) in
                            if let error = error {
                                print("Error fetching properties: \(error.localizedDescription)")
                                return
                            }

                            DispatchQueue.main.async {
                                self.properties = snapshot?.documents.compactMap { doc -> Property? in
                                    let data = doc.data()
                                    return Property(
                                        id: doc.documentID,
                                        imageUrl: data["photo_url"] as? String ?? "",
                                        address: data["city"] as? String ?? "Unknown City",
                                        price: data["price_min"] as? Int ?? 0,
                                        bedrooms: data["bedrooms_min"] as? Int ?? 0,
                                        bathrooms: data["bathrooms_min"] as? Int ?? 0,
                                        listingUrl: data["listing_url"] as? String ?? ""
                                    )
                                } ?? []
                            }
                        }
                    }
                }
                
                
                struct SwipeablePropertiesView: View {
                    @StateObject private var viewModel = PropertyViewModel()

                    var body: some View {
                        ZStack {
                            ForEach(viewModel.properties) { property in
                                PropertyCard(property: property) {
                                    removeProperty(property)
                                }
                                .padding()
                            }
                        }
                        .onAppear {
                            viewModel.fetchProperties() // Fetch properties when view loads
                        }
                    }

                    func removeProperty(_ property: Property) {
                        withAnimation {
                            viewModel.properties.removeAll { $0.id == property.id }
                        }
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
                
            }
        }
        
        
    }
}
