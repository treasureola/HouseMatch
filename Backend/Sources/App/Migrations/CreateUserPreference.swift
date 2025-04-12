import Fluent

struct CreateUserPreference: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_preferences")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("location", .string, .required)
            .field("property_type", .string, .required)
            .field("min_price", .int, .required)
            .field("max_price", .int, .required)
            .field("bedrooms", .int, .required)
            .field("bathrooms", .int, .required)
            .field("square_feet", .int, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_preferences").delete()
    }
}


struct CreateFullUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("first_name", .string, .required)
            .field("last_name", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
