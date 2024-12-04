//New integration part - Frontend

//
//  ContentView.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 9/24/24.
//


import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView{
            VStack {   //the Welcome page
            
                Text("Welcome to")
                    .font(.largeTitle)
                
                Spacer()
                    .bold()
                    .font(.largeTitle)
                Image("House1")
                Image(.houseA)
                    .cornerRadius(50)
                    .imageScale(.large)
                    .foregroundStyle(.blue)
                Text("HouseMatch!")
                    .bold()
                    .font(.largeTitle)
                
                Spacer()
                               //Get Started button
                NavigationLink(destination: AnotherScreen()){
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
            //the view you see when you press "Get Started".
            //the Sign Up page
struct AnotherScreen: View {
    @State private var first_name = ""
    @State private var last_name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmpassword = ""
    
    //validation check for all inputs
    @State private var displayAlert = false
    @State private var alertMessage = ""
    @State private var GotoSignUpScreen = false
    
    var body: some View {
        VStack(alignment: .center){
            
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            Text("Create your account")
                .font(.subheadline)
            
            Spacer()
            TextField("Firstname", text: $first_name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            TextField("Lastname", text: $last_name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.top, 6)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            SecureField("Confirm Password", text: $confirmpassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(destination: SignUpScreen()){
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
            
            
            //the login page
            HStack{
                Text("Already have an account?")
                NavigationLink(destination: LoginScreen(username: first_name)){
                    //the login page
                    HStack{
                        Text("Already have an account?")
                        NavigationLink(destination: LoginScreen(username: first_name, Theemail: email, Thepassword: password)){
                            Text("Login")
                                .foregroundColor(.blue)
                        }
                        .underline()
                    }
                    .padding()
                }
                .navigationTitle("Sign up Page")
            }
            
            //Making sure that all the inputs aren't empty and that
            //password matches confirmpassword
            func areInputsValid() -> Bool {
                return !first_name.isEmpty && !last_name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmpassword
            }
        }
        
    
        
        
        //the login page's view
        struct LoginScreen: View {
            let username: String
            var body: some View {
                VStack{
                    Text("Welcome back, \(username)!") //this displays "Welcome back with the user's first name
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                    //the login page's view
                    struct LoginScreen: View {
                        @State private var Login_email = ""
                        @State private var Login_password = ""
                        
                        let username: String    //passed in from sign-up view
                        let Theemail: String    //passed in from sign-up view
                        let Thepassword: String //passed in from sign-up view
                        
                        func areLoginInputsValid() -> Bool {
                            return !Login_email.isEmpty && !Login_password.isEmpty &&
                            Login_email == Theemail && Login_password == Thepassword
                        }
                        
                        var body: some View {
                            VStack{
                                Text("Welcome back, \(username)!") //this displays "Welcome back with the user's first name
                                    .font(.largeTitle)
                                    .bold()
                                Spacer()
                                
                                TextField("Email", text: $Login_email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(.top, 10)
                                    .padding(.horizontal)
                                
                                SecureField("Password", text: $Login_password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.top, 10)
                                    .padding(.horizontal)
                                Spacer()
                                // Side-by-side buttons
                                HStack {
                                    NavigationLink(destination:PropertiesAndBuildingsSwipe()) {
                                        Text("View Properties")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(areLoginInputsValid() ? Color.blue : Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .disabled(!areLoginInputsValid())
                                    NavigationLink(destination: FindDreamHome()) {
                                        Text("Make Preferences")
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(areLoginInputsValid() ? Color.green : Color.gray)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    .disabled(!areLoginInputsValid())
                                }
                                .navigationTitle("Login")
                            }
                        }
                        
                        
                        
                        
                        
                        
                        
                        
                        
                        //the sign-up page's view
                        struct SignUpScreen: View {
                            @State private var SuccessfulTransition = true
                            @State private var WelcomeTransition = true
                            @State private var AboutUs = false
                            
                            
                            
                            var body: some View {
                                VStack {
                                    if SuccessfulTransition{
                                        Text("Sign up was successful!")
                                            .transition(.opacity) //the animation
                                    }
                                    Spacer()
                                    
                                    if WelcomeTransition{
                                        Text("Welcome to HouseMatch!")
                                            .font(.title)
                                            .transition(.opacity) //the animation
                                    }
                                    
                                    
                                    if AboutUs{
                                        Text("About Us")
                                        //                    .font(.headline)
                                            .font(.largeTitle)
                                            .bold()
                                            .padding(.top)
                                        
                                        Text("An AI-powered platform for matching ideal homes with tenants based on budget, location, preferences, and availability, while also helping landlords find suitable tenants in real time.")
                                            .font(.body)
                                            .padding(.horizontal)
                                            .multilineTextAlignment(.center)
                                            .transition(.opacity)
                                        
                                        Spacer()
                                        
                                        NavigationLink(destination: FindDreamHome()){
                                            Text("Find Your Dream Home")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding()
                                                .background(Color.blue)
                                                .cornerRadius(10)
                                                .padding(.top, 20)
                                        }
                                        
                                    }
                                    Spacer()
                                }
                                .padding()
                                .navigationTitle("Welcome")
                                .onAppear{
                                    // Animation: "Sign Up Successful!" fades away after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            SuccessfulTransition = false
                                        }
                                    }
                                    // Animation: "Welcome to HouseMatch!" fades away after 6 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                        withAnimation {
                                            WelcomeTransition = false
                                        }
                                    }
                                    //Animation: this will show the "About Us" right after "Welcome to HouseMatch!" fades away
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                        withAnimation {
                                            AboutUs = true
                                        }
                                    }
                                    
                                    
                                }
                            }
                        }
                        
                        //the view for User to make House preferences/choices
                        struct FindDreamHome: View {
                            @State private var address = "Select Location"
                            @State private var property_type = "Select Property Type"
                            @State private var price = "Select Price Range"
                            @State private var number_Of_Bedrooms = "Select Number of Bedrooms"
                            @State private var number_Of_Bathrooms = "Select Number of Bathrooms"
                            @State private var number_Of_SquareFeet = "Select Number of Square Feet"
                            
                            
                            let Location = ["Washington, D.C.", "New York City", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami", "Washington, D.C.", "New York City", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami"]
                            
                            let propertyType = ["Single Family Home", "Condo", "Townhouse", "Apartment", "Land", "Multi-Family Home"]
                            
                            let priceRange = ["$500 - $1000" , "$1000 - $1500", "$1500 - $2000", "$2000 - $2500", "$2500 - $3000", "$3000 - $3500", "$3500 - $4000", "$4000 - $4500", "$4500 - $5000"]
                            
                            let numberOfBedrooms = ["1", "2", "3", "4", "5", "6"]
                            
                            let numberOfBathrooms = ["1", "2", "3", "4", "5", "6", "7"]
                            
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
                                        
                                        Address: address,
                                        propertyType: property_type,
                                        price: price,
                                        bedrooms: number_Of_Bedrooms,
                                        bathrooms: number_Of_Bathrooms,
                                        squareFeet: number_Of_SquareFeet
                                    )){
                                        
                                        Text("Finalize Your Dream Home")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(arePreferencesValid() ? Color.blue : Color.gray)
                                            .cornerRadius(10)
                                    }
                                    
                                    .disabled(!arePreferencesValid())  //disable the link if arePreferencesValid() is invalid
                                    .padding(.top, 20)
                                    
                                    .padding()
                                    .navigationTitle("Dream Home")
                                }
                            }
                            func arePreferencesValid() -> Bool {
                                return address != "Select Location" &&
                                property_type != "Select Property Type" &&
                                price != "Select Price Range" &&
                                number_Of_Bedrooms != "Select Number of Bedrooms" &&
                                number_Of_Bathrooms != "Select Number of Bathrooms" &&
                                number_Of_SquareFeet != "Select Number of Square Feet"
                            }
                            
                            
                        }
                        
                        
                        
                        
                        //this is the confirmation page after the user makes their preferences
                        struct ConfirmationPage: View{
                            var Address: String
                        }
                        
                        
                        //the sign-up page's view
                        struct SignUpScreen: View {
                            @State private var SuccessfulTransition = true
                            @State private var WelcomeTransition = true
                            @State private var AboutUs = false
                            
                            
                            
                            var body: some View {
                                VStack {
                                    if SuccessfulTransition{
                                        Text("Sign up was successful!")
                                            .transition(.opacity) //the animation
                                    }
                                    Spacer()
                                    
                                    if WelcomeTransition{
                                        Text("Welcome to HouseMatch!")
                                            .font(.title)
                                            .transition(.opacity) //the animation
                                    }
                                    
                                    
                                    if AboutUs{
                                        Text("About Us")
                                        //                    .font(.headline)
                                            .font(.largeTitle)
                                            .bold()
                                            .padding(.top)
                                        //                Spacer()
                                        
                                        Text("We are an AI-powered platform for matching ideal homes with tenants based on budget, location, preferences, and availability, while also helping landlords find suitable tenants in real time.")
                                            .font(.body)
                                            .padding(.horizontal)
                                            .multilineTextAlignment(.center)
                                            .transition(.opacity)
                                        
                                        Spacer()
                                        //
                                        //the link to view the properties available
                                        NavigationLink(destination: FindDreamHome()){
                                            
                                            Text("Make preferences")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                                .padding()
                                                .background(Color.blue)
                                                .cornerRadius(10)
                                                .padding(.top, 20)
                                        }
                                        
                                        
                                    }
                                    Spacer()
                                }
                                .padding()
                                .navigationTitle("Welcome")
                                .onAppear{
                                    // Animation: "Sign Up Successful!" fades away after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            SuccessfulTransition = false
                                        }
                                    }
                                    // Animation: "Welcome to HouseMatch!" fades away after 6 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                        withAnimation {
                                            WelcomeTransition = false
                                        }
                                    }
                                    //Animation: this will show the "About Us" right after "Welcome to HouseMatch!" fades away
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                        withAnimation {
                                            AboutUs = true
                                        }
                                    }
                                    
                                    
                                }
                            }
                        }
                        
                    
                        
                        
                        
                        //the view for User to make House preferences/choices
                        struct FindDreamHome: View {
                            @State private var address = "Select Location"
                            @State private var property_type = "Select Property Type"
                            @State private var price = "Select Price Range"
                            @State private var number_Of_Bedrooms = "Select Number of Bedrooms"
                            @State private var number_Of_Bathrooms = "Select Number of Bathrooms"
                            @State private var number_Of_SquareFeet = "Select Number of Square Feet"
                            
                            
                            let Location = ["Washington, D.C.", "New York City", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami"]
                            
                            let propertyType = ["Single Family Home", "Condo", "Townhouse", "Apartment", "Land", "Multi-Family Home"]
                            
                            let priceRange = ["$500 - $1000" , "$1000 - $1500", "$1500 - $2000", "$2000 - $2500", "$2500 - $3000", "$3000 - $3500", "$3500 - $4000", "$4000 - $4500", "$4500 - $5000"]
                            
                            let numberOfBedrooms = ["1", "2", "3", "4", "5", "6"]
                            
                            let numberOfBathrooms = ["1", "2", "3", "4", "5", "6", "7"]
                            
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
                                        
                                        Text("Thank you for designing a dream home!")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(arePreferencesValid() ? Color.blue : Color.gray)
                                            .cornerRadius(10)
                                    }
                                    
                                    .disabled(!arePreferencesValid())  //disable the link if arePreferencesValid() is invalid
                                    .padding(.top, 20)
                                    
                                    .padding()
                                    .navigationTitle("Dream Home")
                                }
                            }
                            func arePreferencesValid() -> Bool {
                                return address != "Select Location" &&
                                property_type != "Select Property Type" &&
                                price != "Select Price Range" &&
                                number_Of_Bedrooms != "Select Number of Bedrooms" &&
                                number_Of_Bathrooms != "Select Number of Bathrooms" &&
                                number_Of_SquareFeet != "Select Number of Square Feet"
                            }
                            
                            
                        }
                        
                        
                        
                        
                        
                        //this is the confirmation page after the user makes their preferences
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
                                    
                                    Text("Location: \(Address)")
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
                        
                        
                        
                        
                    }
                }
                .padding()
                .navigationTitle("Confirmation")
            }
            
        }
        
        
        
        
        struct ThankYouPage: View{
            var body: some View{
                VStack{
                    Text("Thank you for your purchased property!")
                        .font(.largeTitle)
                        .padding(.bottom, 20)
                    
                }
                .navigationTitle("Thank You")
                
            }
        }
        
        
        
    }
    
    //a property struct to hold the building data
    struct Property: Hashable{
        var TypeOfbuilding: String
        var imageName: String
        var description: String
    }
    
    struct PropertiesAndBuildingsSwipe: View {
        // an array of Property instances with title, image, and description
        private var properties: [Property] = [
            Property(TypeOfbuilding: "Single Family Home", imageName: "singleFamily_House", description: "A detached, single-family property"),
            Property(TypeOfbuilding: "Condo", imageName: "Condo11", description: "A single unit in a condominium development or building, part of a homeowner’s association (HOA)"),
            Property(TypeOfbuilding: "Townhouse", imageName: "TownHouse1", description: "A single-family property that shares walls with other adjacent homes, part of a homeowner’s association (HOA)"),
            Property(TypeOfbuilding: "Apartment", imageName: "apartment-building", description: "A rental unit within a multi-unit building"),
            Property(TypeOfbuilding: "Land", imageName: "Plot_of_land", description: "An empty plot of land"),
            Property(TypeOfbuilding: "Multi-Family Home", imageName: "Multi-Family_Home", description: "A residential multi-family building (2-4 units)")
        ].reversed() // Optional: reversing the order if needed
        
        var body: some View{
            VStack{
                ZStack{
                    ForEach(properties, id: \.self){ property in
                        CardView(
                            TypeOfbuilding: property.TypeOfbuilding,
                            imageName: property.imageName, descriptions: <#String#>,
                            description: property.description
                        )
                        
                    }
                }
            }
        }
    }
    
    
    //        @State private var currentIndex: Int = 0
    //
    //        var body: some View {
    //            VStack {
    //                ZStack {
    //                    if currentIndex < properties.count {
    //                        let property = properties[currentIndex]
    //                        CardView(
    //                            TypeOfbuilding: property.TypeOfbuilding,
    //                            imageName: property.imageName,
    //                            description: property.description
    //                        )
    //                        .onTapGesture {
    //                            if currentIndex < properties.count - 1 {
    //                                withAnimation{
    //                                    currentIndex += 1   //move to next card
    //                                }
    //                            }
    //                        }
    //                    }
    //                    if currentIndex >= properties.count {
    //                        NavigationLink(destination: FindDreamHome(), label: {
    //                            Text("Find Your Dream Home")
    //                                .font(.headline)
    //                                .foregroundColor(.white)
    //                                .padding()
    //                                .background(Color.blue)
    //                                .cornerRadius(10)
    //                                .padding(.top, 20)
    //                        })
    //
    //                    }
    //                }
    //            }
    //            .navigationTitle("Property & Buildings")
    //        }
    
}

    
    #Preview {
        ContentView()
    }

