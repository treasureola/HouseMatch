//
//  Homepage.swift
//  Simple_GUI
//
//  Created by Sylmira Kailey on 2/16/25.
//


//
//  Homepage.swift
//  Simple_GUI
//
//  Created by Kweku Awuah on 1/26/25.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import SwiftUI

struct Homepage: View {
    @State private var navigateToProperties = false
    
    var body: some View {
        ZStack{
            Color.purple
//                .edgesIgnoringSafeArea(.all)
            VStack{
                VStack{
                    Text("About Us")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.black)
                        .padding(.top, 40)
                    
                    
                    
    
                    Text("We are an AI-powered platform for matching ideal homes with tenants based on budget, location, preferences, and availability, while also helping landlords find suitable tenants in real time.")
                        .font(.body)
        
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .padding(.top, 40)

//                    
                    Spacer()
//

//                        Image(systemName: "house.fill")
//                            .foregroundColor(.white)
//                            .font(.system(size: 90))
            
                    
                    Image(.houseA)  //HouseMatch logo
                        .resizable()
                        .frame(width: 180, height: 180)
                        .cornerRadius(50)
                        .imageScale(.large)
                        .foregroundStyle(.blue)
                    
                    
                    Spacer()

                    Button(action: {
                        fetchPropertiesAndStore { success in
                            if success {
                                navigateToProperties = true //Triggers NavigationLink
                            }
                        }
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
            }
        }
       
    }
    
    func fetchPropertiesAndStore(completion: @escaping (Bool) -> Void) {
        print("Fetching Properties")
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: No authenticated user found.")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userID)
        
        userDoc.getDocument { (document, error) in
            if let error = error {
                print("Error fetching user preferences: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let document = document, document.exists,
                  let userPreferences = document.data()?["preferences"] as? [String: Any] else {
                print("No preferences found for user.")
                completion(false)
                return
            }
            
            guard let location = userPreferences["location"] as? String else {
                print("Error: Missing or invalid user preferences.")
                completion(false)
                return
            }
            
            let propertiesCollection = db.collection("properties")
            propertiesCollection.whereField("assignedUserID", isEqualTo: userID)
                .whereField("viewed", isEqualTo: false)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error checking existing properties: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    let existingUnviewedCount = snapshot?.documents.count ?? 0
                    if existingUnviewedCount >= 50 {
                        print("User already has 50 unviewed properties, skipping fetch.")
                        completion(true)
                        return
                    }
                    
                    fetchFromAPI(userPreferences: userPreferences, userID: userID, db: db)
                    completion(true)
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

#Preview {
    Homepage()
}
