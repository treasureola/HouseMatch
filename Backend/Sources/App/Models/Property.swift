//
//  PropertySearch.swift
//  MyAuthBackend
//
//  Created by Issouf Diarrassouba
// repushing the code
// Issouf Diarrassouba


import Fluent
import Vapor

//Use @unchecked Sendable only if you’re confident that your model instances won’t be accessed concurrently in unsafe ways.

final class Property: Model, Content, @unchecked Sendable {
    static let schema = "properties"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "city")
    var city: String

    @Field(key: "property_type")
    var propertyType: String

    @Field(key: "price")
    var price: Int

    @Field(key: "bedrooms")
    var bedrooms: Int

    @Field(key: "bathrooms")
    var bathrooms: Int

    @Field(key: "square_feet")
    var squareFeet: Int

    init() {}

    init(id: UUID? = nil, city: String, propertyType: String, price: Int, bedrooms: Int, bathrooms: Int, squareFeet: Int) {
        self.id = id
        self.city = city
        self.propertyType = propertyType
        self.price = price
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.squareFeet = squareFeet
    }
}


//     Need to add conditionals for the priuce ranging unless it is going to be a dropdown
    



// struct CreateProperty: Migration {
//     func prepare(on database: Database) -> EventLoopFuture<Void> {
//         database.schema("properties")
//             .id()
//             .field("name", .string, .required)
//             .field("city", .string, .required)
//             .field("state", .string, .required)
//             .field("price", .double, .required)
//             .field("propertyType", .string, .required)
//             .field("capacity", .int, .required)
//             .field("amenities", .array(of: .string), .required)
//             .field("isAvailable", .bool, .required)
//             .create()
//     }

//     func revert(on database: Database) -> EventLoopFuture<Void> {
//         database.schema("properties").delete()
//     }
// }


// // handling the search queries
// struct PropertySearchRequest: Content {
    
//     var city: String?
//     var state: String?
//     var minPrice: Double?
//     var maxPrice: Double?
//     var propertyType: String?
//     var capacity: Int?
// }



