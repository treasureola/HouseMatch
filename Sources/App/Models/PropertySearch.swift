//
//  PropertySearch.swift
//  MyAuthBackend
//
//  Created by Issouf Diarrassouba on 12/1/24.
// repushing the code
// Issouf Diarrassouba


import Fluent
import Vapor

//Use @unchecked Sendable only if you’re confident that your model instances won’t be accessed concurrently in unsafe ways.

final class Property: Model, Content, @unchecked Sendable {
    static let schema = "properties"
//Are we assigning our properties ID's aswell?
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "city")
    var city: String
    
    @Field(key: "state")
    var state: String
    
    @Field(key: "price")
    var price: Double

    @Field(key: "propertyType")
    var propertyType: String

    @Field(key: "capacity")
    var capacity: Int

    @Field(key: "amenities")
    var amenities: [String]

    @Field(key: "isAvailable")
    var isAvailable: Bool

    init() {}

    init(id: UUID? = nil, name: String, city: String, state: String, price: Double, propertyType: String, capacity: Int, amenities: [String], isAvailable: Bool) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.price = price
        self.propertyType = propertyType
        self.capacity = capacity
        self.amenities = amenities
        self.isAvailable = isAvailable
    }
    
//     Need to add conditionals for the priuce ranging unless it is going to be a dropdown
    
}


struct CreateProperty: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("properties")
            .id()
            .field("name", .string, .required)
            .field("city", .string, .required)
            .field("state", .string, .required)
            .field("price", .double, .required)
            .field("propertyType", .string, .required)
            .field("capacity", .int, .required)
            .field("amenities", .array(of: .string), .required)
            .field("isAvailable", .bool, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("properties").delete()
    }
}


// handling the search queries
struct PropertySearchRequest: Content {
    
    var city: String?
    var state: String?
    var minPrice: Double?
    var maxPrice: Double?
    var propertyType: String?
    var capacity: Int?
}



