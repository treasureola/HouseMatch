


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
                NavigationLink(destination: LoginScreenView()) {
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
        .navigationViewStyle(.stack)
    }
}


//the login page's view
struct LoginScreenView: View {
    @EnvironmentObject var userInfo: UserInfo
    @Environment(\.presentationMode) var presentationMode
    
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    
    let db = Firestore.firestore()
    
    func areLoginInputsValid() -> Bool {
        return !loginEmail.isEmpty && !loginPassword.isEmpty && isValidEmail(loginEmail)
    }
    
    func isValidEmail(_ email: String) -> Bool{
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    var body: some View {
        VStack {
            Text("Welcome!")  //this displays "Welcome back with the user's first name
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
                .textContentType(.emailAddress)
                .padding(.top, 10)
                .padding(.horizontal)
                .onChange(of: loginEmail){ _ in errorMessage = ""}
            
            SecureField("Password", text: $loginPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 10)
                .padding(.horizontal)
                .onChange(of: loginPassword){ _ in errorMessage = ""}
            Spacer()
            
            Button(action: handleLogin){
                Text("Login")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 10)
                    .background(areLoginInputsValid() && !isLoading ? Color.purple : Color.gray)
                    .cornerRadius(20)
            }
            .disabled(!areLoginInputsValid() || isLoading) //this would disable if inputs are invalid
            .padding(.horizontal)
            
            if isLoading{
                ProgressView()
                    .padding(.top, 10)
            }
            
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, 5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            HStack{
                Text("Don't have an account?")
                NavigationLink(destination: SignUpView()){
                    Text("Sign Up")
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 20)
        }
    }
    
    func handleLogin() {
        guard areLoginInputsValid() else {
            errorMessage = "Please enter valid email and password"
            return
        }
        isLoading = true
        errorMessage = ""
        
        
        Auth.auth().signIn(withEmail: loginEmail, password: loginPassword) { result, error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Login failed: \(error.localizedDescription)"
            } else if let user = result?.user{
                //successful
                fetchFirestoreUserInfo(uid: user.uid)
                print("Login successful for user: \(user.uid)")
            } else{
                errorMessage = "Unknown error occurred during login"
            }
        }
    }
    
    func fetchFirestoreUserInfo(uid: String){
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(uid)
        userDoc.getDocument { (document, error) in
            if let document = document, document.exists, let userData = document.data() {
                DispatchQueue.main.async{
                    userInfo.firstName = userData["first_name"] as? String ?? ""
                    userInfo.lastName = userData["last_name"] as? String ?? ""
                    userInfo.email = userData["email"] as? String ?? ""
                    print("User fetched correctly")
                }
            } else {
                print ("User doc does not exist")
                errorMessage = "Could not load user profile. Please try again."
            }
        }
    }
}


//This is the view you see when you press "Get Started".
//The Sign Up page
struct SignUpView: View {
    @EnvironmentObject var userInfo: UserInfo
    @Environment(\.presentationMode) var presentationMode
    
    @State private var password = ""
    @State private var confirmPassword = ""
    
    //Error states
    @State private var generalError = ""
    @State private var firstNameError = ""
    @State private var lastNameError = ""
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    @State private var isLoading = false
    @State private var navigateToLogin = false
    
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
            ValidatedTextField(
                placeholder: "First Name",
                text: $userInfo.firstName,
                errorMessage: $firstNameError,
                validation: validateFirstName
            )
                
            
            //Last Name
            ValidatedTextField(
                placeholder: "Last Name",
                text: $userInfo.lastName,
                errorMessage: $lastNameError,
                validation: validateLastName
            )
            
            //Email
            ValidatedTextField(
                placeholder: "Email",
                text: $userInfo.email,
                errorMessage: $emailError,
                keyboardType: .emailAddress,
                autocapitalization: .none,
                textContentType: .emailAddress,
                validation: validateEmail
            )
            
            
            //Password
            ValidatedSecureField(
                placeholder: "Password",
                text: $password,
                errorMessage: $passwordError,
                textContentType: .newPassword,
                validation: validatePassword
            )
            
            //Confirm Password
            ValidatedSecureField(
                placeholder: "Confirm Password",
                text: $confirmPassword,
                errorMessage: $confirmPasswordError,
                textContentType: .newPassword,
                validation: validateConfirmPassword
            )
            
            if !generalError.isEmpty{
                Text(generalError)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, 5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            Button(action: handlingSignUp) {
                Text("Sign Up")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .padding(.vertical, 10)
                    .background(canAttemptSignUp() && !isLoading ? Color.purple : Color.gray)
                    .cornerRadius(20)
            }
            .disabled(!canAttemptSignUp() || isLoading)
            .padding(.horizontal)
            .padding(.bottom)
            
            NavigationLink(destination: LoginScreenView(), isActive: $navigateToLogin){
                EmptyView()
            }
            
            if isLoading{
                ProgressView()
                    .padding(.top, 10)
            }
        }
        .navigationTitle("Create Account")
        .padding(.top, 5)
        .onAppear{
            
        }
    }
    
    func canAttemptSignUp() -> Bool {
        return !userInfo.firstName.isEmpty &&
                !userInfo.lastName.isEmpty &&
                !userInfo.email.isEmpty &&
                userInfo.email.contains("@") &&
                !password.isEmpty &&
                password == confirmPassword &&
                password.count >= 8 &&
                generalError.isEmpty
    }
    
    func validateAllFields() -> Bool{
        validateFirstName()
        validateLastName()
        validateEmail()
        validatePassword()
        validateConfirmPassword()
        
        return firstNameError.isEmpty &&
                lastNameError.isEmpty &&
                emailError.isEmpty &&
                passwordError.isEmpty &&
                confirmPasswordError.isEmpty
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
        if password.isEmpty {
            passwordError = "Password cannot be empty."
        } else if password.count < 8 {
            passwordError = "Password must be at least 8 characters." // Firebase requirement
        } else {
            passwordError = ""
        }
    }
    
    func validateConfirmPassword() {
        if confirmPassword.isEmpty {
            confirmPasswordError = "Please confirm your password."
        } else if password != confirmPassword {
            confirmPasswordError = "Passwords do not match."
        } else {
            confirmPasswordError = ""
        }
        generalError = ""
    }
    
    func handlingSignUp() {  //Was newly added
        
        print("In Handling SIgn Up")
        
        generalError = ""
        
        guard validateAllFields() else{
            print("Validation failed.")
            generalError = "Please fix the errors above"
            return
        }
        
        isLoading = true
        
        Auth.auth().createUser(withEmail: userInfo.email, password: password) { authResult, error in
            isLoading = false
            if let error = error {
                print("Error creating user: \(error.localizedDescription)")
                generalError = error.localizedDescription
            } else if let user = authResult?.user {
                print("User created successfully! UID: \(user.uid)")
                saveUserData(uid: user.uid)
                
                UserDefaults.standard.set(true, forKey: "showLogin")
                
                do{
                    try Auth.auth().signOut()
                    print("user signned out")
                } catch let signOutError {
                    print("Sign out error: \(signOutError.localizedDescription)")
                }
                
                navigateToLogin = true
            } else{
                generalError = "An error occurred while creating your account."
            }
        }
    }
    
    func saveUserData(uid: String){
        let userDoc = db.collection("users").document(uid)
        let userData: [String: Any] = [
            "first_name": userInfo.firstName,
            "last_name": userInfo.lastName,
            "email": userInfo.email,
            "createdAt": Timestamp()
        ]
        userDoc.setData(userData){ error in
            if let error = error {
                print("Firestore error saving user data: \(error.localizedDescription)")
            } else {
                print("User saved in Firestore successfully")
            }
        }
    }
}

struct ValidatedTextField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var errorMessage: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var textContentType: UITextContentType? = nil
    let validation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .textContentType(textContentType)
                .padding(.horizontal)
                .onChange(of: text) { _ in
                    validation() // Validate on change
                    errorMessage = ""
                }
                .onDisappear(perform: validation)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 6)
    }
}

struct ValidatedSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var errorMessage: String
    var textContentType: UITextContentType? = nil
    let validation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            SecureField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(textContentType)
                .padding(.horizontal)
                .onChange(of: text) { _ in
                    validation()
                    errorMessage = ""
                }
                .onDisappear(perform: validation)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 6)
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
    @State private var number_Of_Bathrooms = "Select Number of Bathrooms"
    @State private var number_Of_SquareFeet = "Select Number of Square Feet"
    @State private var navigateToConfirmation = false
    
    @EnvironmentObject var userInfo: UserInfo
    
    let locations =
    ["Select Location"] + [
        "Washington, D.C.",
        "New York",
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
                    ForEach(Array(Set(locations)), id: \.self) { location in
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
                Text("Number of Square Footage")
                    .padding(.top, 20)
                    .padding(.horizontal)
                Spacer()
                Picker(
                    "Number of Square Footage",
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
            Button(action: {
                if arePreferencesValid() {
                    savePreferences()
                    navigateToConfirmation = true
                }
            }) {
                Text("Confirm Preferences")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .background(
                        arePreferencesValid() ? Color.blue : Color.gray
                    )
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            .navigationTitle("Dream Home")
            .background(
                NavigationLink(
                    destination: ConfirmationPage(
                        address: address,
                        propertyType: property_type,
                        price: price,
                        bedrooms: number_Of_Bathrooms,
                        bathrooms: number_Of_Bedrooms,
                        squareFeet: number_Of_SquareFeet
                    ),
                    isActive: $navigateToConfirmation
                ){
                    EmptyView()
                }
                .hidden()
            )
        }
        .navigationTitle("Dream Home")
        .padding(.top, 5)
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
    
    func savePreferences() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found.")
            return
        }
        let (minPrice, maxPrice) = parsePriceRange(price)
        let cleanSquareFeet = number_Of_SquareFeet.replacingOccurrences(
            of: "+",
            with: ""
        )
        let userDoc = db.collection("users").document(userID)
        let preferences: [String: Any] = [
            "location": address,
            "propertyType": propertyType,
            "minPrice": minPrice,
            "maxPrice": maxPrice,
            "bedrooms": number_Of_Bedrooms,
            "bathrooms": number_Of_Bathrooms,
            "squareFeet": cleanSquareFeet,
            "timestamp": Timestamp(),
        ]
        
        userDoc.setData(["preferences": preferences], merge: true) { error in
            if let error = error {
                print("Error saving preferences: \(error.localizedDescription)")
            } else {
                print("Preferences saved successfully")
                DispatchQueue.main.async {
                    userInfo.hasPreferences = true
                }
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
}
            
//this is the confirmation page after the user/client makes their preferences
struct ConfirmationPage: View {
    var address: String
    var propertyType: String
    var price: String
    var bedrooms: String
    var bathrooms: String
    var squareFeet: String
    
    @Environment(\.dismiss) var dismiss

    @State private var navigateToHomepage = false
    @State private var navigateBack = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Confirm Preferences")
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
            
            HStack{
                Button(action: {
                    navigateBack = true  //Triggers navigation
                }) {
                    Text("Go Back")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                }
                .background(
                    NavigationLink(
                        destination: FindDreamHome(),
                        isActive: $navigateBack
                    ){
                        EmptyView()
                    }
                )
                
                Spacer()
                
                Button(action: {
                    navigateToHomepage = true  //Triggers navigation
                }) {
                    Text("Confirm and Submit")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                }
                .background(
                    NavigationLink(
                        destination: ConfirmationNavigation(),
                        isActive: $navigateToHomepage
                    ){
                        EmptyView()
                    }
                )
            }
        }
        .padding()
        .navigationTitle("Confirmation")
    }
}

struct ConfirmationNavigation: View {
    @State private var showToast = true
    @State private var navigateToHomepage = false
    
    var body: some View{
        ZStack{
            Homepage()
                .opacity(navigateToHomepage ? 1 : 0)
            
            if showToast{
                VStack{
                    Spacer()
                    Text("Your preferences have been saved!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                    Spacer()
                }
                .transition(.move(edge: .bottom))
                .onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                        withAnimation{
                            showToast = false
                            navigateToHomepage = true
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
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



                
            #Preview {
                WelcomeView()
            }

