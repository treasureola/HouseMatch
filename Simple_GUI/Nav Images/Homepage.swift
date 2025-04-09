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
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                Color.purple
                VStack{
                    VStack{
                        Text("About Us")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.black)
                            .padding(.top, 40)
                        
                        
                        
                        
                        Text("Discover apartments and houses tailored for you! Hit the button to find your match!")
                            .font(.body)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                            .padding(.top, 40)
                        
                        Spacer()
                        
                        
                        Image(.houseA)  //HouseMatch logo
                            .resizable()
                            .frame(width: 180, height: 180)
                            .cornerRadius(50)
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                        
                        
                        Spacer()
                        
                        Button(action: {
                            isLoading = true
                            fetchPropertiesAndStore { success in
                                DispatchQueue.main.async{
                                    isLoading = false
                                    if success {
                                        navigateToProperties = true //Triggers NavigationLink
                                    } else {
                                        print("Failed to fetch properties")
                                    }
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
                        
                        if isLoading{
                            ProgressView("Fetching Properties...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.top, 10)
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
                .whereField("city", isEqualTo: location)
                .getDocuments { (snapshot, error) in
                    if let error = error {
                        print("Error checking existing properties: \(error.localizedDescription)")
                        completion(false)
                        return
                    }
                    
                    let existingUnviewedCount = snapshot?.documents.count ?? 0
                    if existingUnviewedCount >= 50 {
                        print("User already has 50 unviewed properties, skipping fetch.")
                        DispatchQueue.main.async{
                            completion(true)
                        }
                        return
                    }
                    
                    fetchFromAPI(userPreferences: userPreferences, userID: userID, db: db) { success in
                        completion(success)
                    }
                }
        }
    }
    
    func fetchFromAPI(userPreferences: [String: Any], userID: String, db: Firestore, completion: @escaping (Bool) -> Void) {
        
        guard let location = userPreferences["location"] as? String,
              let maxPrice = userPreferences["maxPrice"] as? Int,
              let bedrooms = userPreferences["bedrooms"] as? String,
              let bathrooms = userPreferences["bathrooms"] as? String else {
            print("Error: Missing or invalid user preferences.")
            completion(false)
            return
        }
        
    
        // Format query parameters based on user preferences
        let formattedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
        let urlString = "https://realtor-search.p.rapidapi.com/properties/search-rent?location=city:\(formattedLocation)&price_max=\(maxPrice)&beds_min=\(bedrooms)&baths_min=\(bathrooms)&resultsPerPage=100&sortBy=best_match"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("41074491b8msh897384f5dfbdfd4p122b3cjsn3bf3b6b434f6", forHTTPHeaderField: "x-rapidapi-key")
        request.setValue("realtor-search.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error fetching properties from API: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let data = data else {
                print("No data received from API")
                completion(false)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let results = json?["data"] as? [String: Any],
                      let properties = results["results"] as? [[String: Any]] else {
                    print("Invalid response format from API")
                    completion(false)
                    return
                }
                
                if properties.isEmpty {
                    print("No new properties found matching criteria from API")
                    completion(true)
                    return
                }

                let group = DispatchGroup()
                let db = Firestore.firestore()
                let propertiesCollection = db.collection("properties")

                for property in properties {
                    
                    group.enter()

//                    let categories = ((property["details"] as? [[String: Any]])?.compactMap { $0["text"] as? [String] }.flatMap { $0 }) ?? []
//                    let sanitizedCategories = categories.map { $0.replacingOccurrences(of: "/", with: "-") }
//                    
//                    let amenitiesArray = ((property["details"] as? [[String: Any]])?
//                        .compactMap { $0["text"] as? [String] }
//                        .flatMap { $0 }
//                    ) ?? []
                    
                    
                    let priceValue: Int
                    if let priceAny = property["list_price_max"] {
                        if let priceInt = priceAny as? Int {
                            priceValue = priceInt
                        } else if let priceDouble = priceAny as? Double {
                            priceValue = Int(priceDouble) // Convert Double to Int if necessary
                        } else {
                            priceValue = 0 // Default price
                        }
                    } else {
                        priceValue = 0 // Default price
                    }

                    let bedsValue: Int
                     if let bedsAny = (property["description"] as? [String: Any])?["beds_max"] {
                         if let bedsInt = bedsAny as? Int {
                             bedsValue = bedsInt
                         } else if let bedsDouble = bedsAny as? Double {
                            bedsValue = Int(bedsDouble)
                         } else {
                             bedsValue = 0
                         }
                     } else {
                         bedsValue = 0
                     }

                    let bathsValue: Int
                     if let bathsAny = (property["description"] as? [String: Any])?["baths_max"] {
                         if let bathsInt = bathsAny as? Int {
                            bathsValue = bathsInt
                         } else if let bathsDouble = bathsAny as? Double {
                            bathsValue = Int(bathsDouble)
                         } else {
                             bathsValue = 0
                         }
                     } else {
                         bathsValue = 0
                     }

                    let sqftValue: Int
                     if let sqftAny = (property["description"] as? [String: Any])?["sqft_max"] {
                         if let sqftInt = sqftAny as? Int {
                            sqftValue = sqftInt
                         } else if let sqftDouble = sqftAny as? Double {
                             sqftValue = Int(sqftDouble)
                         } else {
                             sqftValue = 0
                         }
                     } else {
                         sqftValue = 0
                     }

                    let amenitiesArray = ((property["details"] as? [[String: Any]])?
                        .compactMap { $0["text"] as? [String] }
                        .flatMap { $0 }
                    ) ?? []

                     let petPolicy = property["pet_policy"] as? [String: Any]
                     let catsAllowed = petPolicy?["cats"] as? Bool ?? false
                     let dogsAllowed = petPolicy?["dogs"] as? Bool ?? false



                    let propertyData: [String: Any] = [
                        "property_id": property["property_id"] as? String ?? "",
                        "listing_id": property["listing_id"] ?? "",
                        "status": property["status"] ?? "Unknown",
                        "photo_url": (property["primary_photo"] as? [String: Any])?["href"] ?? "",
                        "address": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["line"] as? String ?? "",
                        "city": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["city"] ?? "",
                        "state_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["state_code"] ?? "",
                        "postal_code": ((property["location"] as? [String: Any])?["address"] as? [String: Any])?["postal_code"] ?? "",
                        "price": priceValue,
                        "bedrooms": bedsValue,
                        "bathrooms": bathsValue,
                        "square_feet": sqftValue,
                        "listing_url": property["href"] ?? "",
                        "amenities": amenitiesArray,
                        "petFriendly": catsAllowed || dogsAllowed,
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
                        group.leave()
                    }
                }
                group.notify(queue: .main){
                    print("All properties saved!")
                    completion(true)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(false)
            }
        }
        dataTask.resume()
    }
}

#Preview {
    Homepage()
}
