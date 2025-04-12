import Fluent

struct CreateTodo: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("todos")
            .id()
            .field("title", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("todos").delete()
    }
}

struct AddSquareFeetToProperty: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("properties")
            .field("square_feet", .int, .required)
            .update()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("properties")
            .deleteField("square_feet")
            .update()
    }
}

struct CreateProperty: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("properties")
            .id()
            .field("city", .string, .required)
            .field("property_type", .string, .required)
            .field("price", .int, .required)
            .field("bedrooms", .int, .required)
            .field("bathrooms", .int, .required)
            .field("square_feet", .int, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("properties").delete()
    }
}
