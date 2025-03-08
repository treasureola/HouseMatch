import Foundation
import Vapor
import Fluent

// ----------------------------------------------------- Creating User Table ----------------------------------------------------- \\

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}

// ----------------------------------------------------- USER MODEL ----------------------------------------------------- \\

final class User: Model, Content, Authenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    init() {}

    init(id: UUID? = nil, email: String) {
        self.id = id ?? UUID()
        self.email = email
    }
}



// ----------------------------------------------------- FIREBASE AUTH MIDDLEWARE ----------------------------------------------------- \\

struct FirebaseAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing or invalid Firebase token")
        }

        let verifiedUser = try await FirebaseAuthService.verifyToken(token)

        // Check if the user exists in the database
        if let user = try await User.query(on: request.db)
            .filter(\.$email == verifiedUser.email)
            .first() {
            request.auth.login(user)
        } else {
            // Optionally create a new user if not found
            let newUser = User(email: verifiedUser.email)
            try await newUser.save(on: request.db)
            request.auth.login(newUser)
        }

        return try await next.respond(to: request)
    }
}

// ----------------------------------------------------- USER INPUT ----------------------------------------------------- \\

struct UserInput: Content {
    let email: String
    let password: String?
    // Token is Optional
    let token: String?
}

// ----------------------------------------------------- TOKEN RESPONSE ----------------------------------------------------- \\

struct TokenResponse: Content {
    let token: String
}

// ----------------------------------------------------- USER PREFERENCE MODEL ----------------------------------------------------- \\

struct UserPreferenceInput: Content {
    let location: String
    let propertyType: String
    let minPrice: Int
    let maxPrice: Int
    let bedrooms: Int
    let bathrooms: Int
    let squareFeet: Int
}


