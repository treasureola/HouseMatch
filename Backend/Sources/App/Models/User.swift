import Foundation
import Vapor
import Fluent

// MARK: - CreateUser Migration (Updated)

struct CreateUser: AsyncMigration {
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

// MARK: - User Model

final class User: Model, Content, Authenticatable, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "first_name")
    var firstName: String

    @Field(key: "last_name")
    var lastName: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(id: UUID? = nil, email: String, firstName: String, lastName: String) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
    }
}

// MARK: - Firebase Auth Middleware

struct FirebaseAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing or invalid Firebase token")
        }

        let verifiedUser = try await FirebaseAuthService.verifyToken(token)

        if let user = try await User.query(on: request.db)
            .filter(\.$email == verifiedUser.email)
            .first() {
            request.auth.login(user)
        } else {
            // Default name fallback for Firebase users
            let newUser = User(
                email: verifiedUser.email,
                firstName: "Firebase",
                lastName: "User"
            )
            try await newUser.save(on: request.db)
            request.auth.login(newUser)
        }

        return try await next.respond(to: request)
    }
}

// MARK: - DTOs

struct UserInput: Content {
    let email: String
    let password: String?
    let token: String?
}

struct RegisterInput: Content {
    let email: String
    let firstName: String
    let lastName: String
}

struct TokenResponse: Content {
    let token: String
}

struct UserPreferenceInput: Content {
    let location: String
    let propertyType: String
    let minPrice: Int
    let maxPrice: Int
    let bedrooms: Int
    let bathrooms: Int
    let squareFeet: Int
}
