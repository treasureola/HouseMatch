//New integration part - Frontend !!

//
//  ContentView.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 9/24/24.
//


import SwiftUI

//This is the front page/Welcome page of the application
struct ContentView: View {
    
    @State private var firstName = ""
    @State private var email = ""
    @State private var password = ""
        
    var body: some View {
        
        NavigationView{
            VStack {   //stacking elements vertically
            
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
                NavigationLink(destination: LoginScreenView(username: firstName, theEmail: email, thePassword: password)){
                    Text("Get Started")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(15)
                    
                }
            }
            .padding()
        }
        
       
    
    }
}



//the login page's view
struct LoginScreenView: View {
//    @State private var username = ""
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    
//    Text("Welcome back, \(username)!") //this displays
    
    let username: String    //strings parameters that were passed in at sign-up view
    let theEmail: String    //strings parameters that were passed in at sign-up view
    let thePassword: String //strings parameters that were passed in at sign-up view
    
    func areLoginInputsValid() -> Bool {
        return !loginEmail.isEmpty && !loginPassword.isEmpty && loginEmail == theEmail && loginPassword == thePassword
    }
    
    var body: some View {
        VStack{
            Text("Welcome back!")
                .font(.largeTitle)
                .bold()
//            Spacer()
            
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

            
        
            // Side-by-side buttons
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
}



//This is the view you see when you press "Get Started".
//The Sign Up page
struct SignUpView: View {
//    @State private var firstName = ""
//    @State private var lastName = ""
//    @State private var email = ""
    
    //3N. To help access the shared 'UserInfo' object
    @EnvironmentObject var userInfo: UserInfo
    
  
    @State private var password = ""
    @State private var confirmPassword = ""
    
    //Was newly added
    @State private var firstNameError = ""
    @State private var lastNameError = ""
    @State private var emailError = ""
    @State private var passwordError = ""
    @State private var confirmPasswordError = ""
    
    var body: some View {
        VStack(alignment: .center){
            
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            Text("Create your account")
                .font(.subheadline)
            
            Spacer()
            //input for firstname
            TextField("Firstname", text: $userInfo.firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
                .onChange(of: userInfo.firstName) { validateFirstName()}   //Was newly added
            
            if !firstNameError.isEmpty {
                            Text(firstNameError)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
            
            //input for lastname
            TextField("Lastname", text:  $userInfo.lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
                .onChange(of: userInfo.lastName) { validateLastName()}    //Was newly added
            
            if !lastNameError.isEmpty {          //Was newly added
                            Text(lastNameError)
                                .foregroundColor(.red)
                                .font(.footnote)
                        }
            
            
            //input for email
            TextField("Email", text: $userInfo.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.top, 6)
                .padding(.horizontal)
                .onChange(of: userInfo.email) { validateEmail()}     //Was newly added
            
            if !emailError.isEmpty {     //Was newly added
                           Text(emailError)
                               .foregroundColor(.red)
                               .font(.footnote)
                       }
            
            
            
            //input for password
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
                .onChange(of: password) { validatePassword()}    //if there was a change on the password then execute the func:validatePassword()
            
            if !passwordError.isEmpty {                       //Was newly added
                           Text(passwordError)
                               .foregroundColor(.red)
                               .font(.footnote)
                       }
            
            //input for confirming password (must be the same as the )
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
                .onChange(of: confirmPassword) { validateConfirmPassword()}     //if there was a change on confirm password, then execute the func:validateConfirmPassword()
            
            if !confirmPasswordError.isEmpty {                //Was newly added
                          Text(confirmPasswordError)
                              .foregroundColor(.red)
                              .font(.footnote)
                      }
            
            Spacer()
            Button(action: handlingSignUp){     //Was newly added
                NavigationLink(destination: LoginScreenView(username:  userInfo.firstName, theEmail: userInfo.email, thePassword: password)){
                    Text("Sign up")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(areInputsValid() ? Color.purple : Color.gray) //if its invalid the sign-up will be  gray
                        .cornerRadius(20)
                        .padding(.horizontal)
                }
                .disabled(!areInputsValid()) //this would disable if inputs are invalid
                .padding(.top, 30)
            }
                
                .padding()
            
            .navigationTitle("Sign up Page")
        }
    }
        
    
    
       
    //Making sure that all the inputs aren't empty and that
    //password matches confirmpassword
    func areInputsValid() -> Bool {
        return !userInfo.firstName.isEmpty && !userInfo.lastName.isEmpty && !userInfo.email.isEmpty && !password.isEmpty && password == confirmPassword
    }
    
    
    // Field-specific validation        //Was newly added
        func validateFirstName() {
            firstNameError =  userInfo.firstName.isEmpty ? "First name cannot be empty." : ""
        }
        
        func validateLastName() {
            lastNameError =  userInfo.lastName.isEmpty ? "Last name cannot be empty." : ""
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
    //Was newly added
  
    
    func handlingSignUp() {     //Was newly added
          // Re-validate all fields on sign-up attempt
          validateFirstName()
          validateLastName()
          validateEmail()
          validatePassword()
          validateConfirmPassword()
          
          if areInputsValid() {
              print("Sign up success")
          }
      }
    
    
}



    //the sign-up page's view
    struct SignUpTransitionView: View {
        @State private var successfulTransition = true
        @State private var welcomeTransition = true
        @State private var aboutUs = false
        @State private var displayTabView = false //to control TabView
        
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
        
        let Location = ["Washington, D.C.", "New York City", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami"]
        
        let propertyType = ["Single Family Home", "Condo", "Townhouse", "Apartment", "Land", "Multi-Family Home"]
        //add a drop dowm menu
        let priceRange = ["$500 - $1000" , "$1000 - $1500", "$1500 - $2000", "$2000 - $2500", "$2500 - $3000", "$3000 - $3500", "$3500 - $4000", "$4000 - $4500", "$4500 - $5000"]
       
        //using Array(1..6) = creates an array with integers from 1 to 6
        //map {"\($0)"} = this maps the integers to its string representation
        let numberOfBedrooms = Array(1...6).map {"\($0)"}
        
        let numberOfBathrooms = Array(1...6).map {"\($0)"}
                
        let numberOfSquareFeet = ["500+","600+", "700+", "800+", "900+", "1000+", "1200+", "1500+", "2000+", "2500+", "3000+", "3500+", "4000+", "5000+", "6000+"]
        
        
        var body: some View {
            VStack(alignment: .center, spacing: 20){
                Text("Personalize Your Dream Home!")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
                Spacer()
                
                //For the location/Address
                HStack{
                    Text("Location")
                        .padding(.top, 8)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Location", selection: $address){
                        ForEach(Location, id: \.self){ location in
                            Text(location)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width:200)
                }
                
                //For the property type
                HStack{
                    Text("Building Type")
                        .padding(.top, 8)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Property Type", selection: $property_type){
                        ForEach(propertyType, id: \.self){ property in
                            Text(property)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width:200)
                }
                
                //For price range
                HStack{
                    Text("Price Range")
                        .padding(.top, 7)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Price Range", selection: $price){
                        ForEach(priceRange, id: \.self){ price in
                            Text(price)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width:200)
                }
                
                
                //For number of Bedrooms
                HStack{
                    Text("Number of Bedrooms")
                        .padding(.top, 20)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Number of Bedrooms", selection: $number_Of_Bedrooms){
                        ForEach(numberOfBedrooms, id: \.self){ number in
                            Text(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width:200)
                }
                
                HStack{
                    Text("Number of Bathrooms")
                        .padding(.top, 20)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Number of Bathrooms", selection: $number_Of_Bathrooms){
                        ForEach(numberOfBathrooms, id: \.self){ number in
                            Text(number)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width:200)
                }
                
                HStack{
                    Text("Number of SquareFootage")
                        .padding(.top, 20)
                        .padding(.horizontal)
                    Spacer()
                    Picker("Number of SquareFootage", selection: $number_Of_SquareFeet){
                        ForEach(numberOfSquareFeet, id: \.self){ number in
                            Text(number)
                            
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width:200)
                }
                
                Spacer()
                
                //Redirects to the confirmation page
                //It takes in the user preferences from "FindDreamHome" such as (address, property_type, price,number_Of_Bedrooms,number_Of_Bathrooms, number_Of_SquareFeet)
                NavigationLink(destination: ConfirmationPage(
                    
                    address: address,
                    propertyType: property_type,
                    price: price,
                    bedrooms: number_Of_Bedrooms,
                    bathrooms: number_Of_Bathrooms,
                    squareFeet: number_Of_SquareFeet
                )){
                    
                    Text("Thank you for designing your dream home!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(arePreferencesValid() ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                
                .disabled(!arePreferencesValid())  //disables the link if arePreferencesValid() is invalid
                .padding(.top, 20)
                
                .padding()
                .navigationTitle("Dream Home")
            }
        }
        //a function to check that all the inputs aren't empty and a selection has been made
        func arePreferencesValid() -> Bool {
            return address != "Select Location" &&
            property_type != "Select Property Type" &&
            price != "Select Price Range" &&
            number_Of_Bedrooms != "Select Number of Bedrooms" &&
            number_Of_Bathrooms != "Select Number of Bathrooms" &&
            number_Of_SquareFeet != "Select Number of Square Feet"
        }
        
        
    }
    
    
    //this is the confirmation page after the user/client makes their preferences
    struct ConfirmationPage: View{
        var address: String
        var propertyType : String
        var price: String
        var bedrooms: String
        var bathrooms: String
        var squareFeet: String
        
        var body: some View{
            VStack(alignment: .center, spacing:20){
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
                
                NavigationLink(destination: ThankYouPage()){
                    
                    Text("Confirm and Submit")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("Confirmation")
        }
        
    }


    struct ThankYouPage: View{
        var body: some View{
            VStack{
                Text("Thank you. Your housing preferences have been saved")
                    .font(.largeTitle)
                    .padding(.bottom, 20)
            }
            .navigationTitle("Thank You")
            
        }
    }
    
    //a property struct to hold the building data
    //we use hasable becuase we use 'Property struct' as the identifier in the ForEach loop
struct Property: Hashable{
        var typeOfBuilding: String
        var imageName: String
        var description: String
    }
    
struct PropertiesAndBuildingsSwipe: View {
    // an array of Property instances with title, image, and description
    private var properties: [Property] = [
        Property(typeOfBuilding: "Single Family Home", imageName: "singleFamily_House", description: "A detached, single-family property"),
        Property(typeOfBuilding: "Condo", imageName: "Condo11", description: "A single unit in a condominium development or building, part of a homeowner’s association (HOA)"),
        Property(typeOfBuilding: "Townhouse", imageName: "TownHouse1", description: "A single-family property that shares walls with other adjacent homes, part of a homeowner’s association (HOA)"),
        Property(typeOfBuilding: "Apartment", imageName: "apartment-building", description: "A rental unit within a multi-unit building"),
        Property(typeOfBuilding: "Land", imageName: "Plot_of_land", description: "An empty plot of land"),
        Property(typeOfBuilding: "Multi-Family Home", imageName: "Multi-Family_Home", description: "A residential multi-family building (2-4 units)")
    ].reversed() // Optional: reversing the order if needed
    
    var body: some View{
        VStack{
            ZStack{
                ForEach(properties, id: \.self){ property in
                    propertyCardView(
                        typeOfBuilding: property.typeOfBuilding,
                        imageName: property.imageName,
                        description: property.description
                    )
                    
                }
            }
        }
    }
}
        
    
#Preview {
    ContentView()
}

