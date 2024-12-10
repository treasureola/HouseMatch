//New integration part - Frontend !!

//
//  WelcomeView.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 9/24/24.
//


import SwiftUI

//This is the front page/Welcome page of the application
struct WelcomeView: View {
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
                NavigationLink(destination: SignUpView()){
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

//This is the view you see when you press "Get Started".
//The Sign Up page
struct SignUpView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
            
    var body: some View {
        VStack(alignment: .center){
            
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            Text("Create your account")
                .font(.subheadline)
            
            Spacer()
            //input for firstname
            TextField("Firstname", text: $firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            //input for lastname
            TextField("Lastname", text: $lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            //input for email
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(.top, 6)
                .padding(.horizontal)
            
            //input for password
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            //input for confirming password (must be the same as the )
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.top, 6)
                .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(destination: SignUpTransitionView()){
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
                NavigationLink(destination: LoginScreenView(username: firstName, theEmail: email, thePassword: password)){
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
        return !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }
}


//the login page's view
struct LoginScreenView: View {
    @State private var loginEmail = ""
    @State private var loginPassword = ""
    
    let username: String    //passed in from sign-up view
    let theEmail: String    //passed in from sign-up view
    let thePassword: String //passed in from sign-up view
    
    func areLoginInputsValid() -> Bool {
        return !loginEmail.isEmpty && !loginPassword.isEmpty &&
        loginEmail == theEmail && loginPassword == thePassword
    }
    
    var body: some View {
        VStack{
            Text("Welcome back, \(username)!") //this displays "Welcome back with the user's first name
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
}
    
    //the sign-up page's view
    struct SignUpTransitionView: View {
        @State private var successfulTransition = true
        @State private var welcomeTransition = true
        @State private var aboutUs = false
        
        var body: some View {
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
                
                if aboutUs{
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
        @State private var number_Of_Bathrooms = "Select Number of Bathrooms"
        @State private var number_Of_SquareFeet = "Select Number of Square Feet"
        
        let Location = ["Washington, D.C.", "New York City", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami", "Los Angeles", "Boston", "Chicago", "Houston", "Philadelphia", "San Francisco", "Denver", "Salt Lake City", "Phoenix", "Atlanta", "Miami"]
        
        let propertyType = ["Single Family Home", "Condo", "Townhouse", "Apartment", "Land", "Multi-Family Home"]
        
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
    WelcomeView()
}

