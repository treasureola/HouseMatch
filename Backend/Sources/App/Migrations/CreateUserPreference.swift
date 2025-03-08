//
//  CreateUserPreference.swift
//  Backend_Property_Listing
//
//  Created by Issouf Diarrassouba 
//

import Fluent

struct CreateUserPreference: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_preferences")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("location", .string, .required)
            .field("property_type", .string, .required)
            .field("min_price", .int, .required)
            .field("max_price", .int, .required)
            .field("bedrooms", .int, .required)
            .field("bathrooms", .int, .required)
            .field("square_feet", .int, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_preferences").delete()
    }
}
