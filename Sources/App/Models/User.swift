//
//  User.swift
//  MyAuthBackend
//
//  Created by Issouf Diarrassouba on 12/1/24.
//
import Foundation
import Vapor
import Fluent
import JWT

// ----------------------------------------------------- Creating User ----------------------------------------------------- \\

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("passwordHash", .string, .required)
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}

// ---------------------------------------------------------------------------------------------------------------------------- \\

//Use @unchecked Sendable only if you’re confident that your model instances won’t be accessed concurrently in unsafe ways.
final class User: Model, Content, Authenticatable, @unchecked Sendable{
    // Defines the table name in the db
    static let schema = "users"
    // for nosql if is "_id"
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "passwordHash")
    var passwordHash: String
    
    init() {}
    
    init(id: UUID? = nil, email: String, passwordHash: String) {
        if let existingId = id {
            self.id = existingId // Keep the passed ID if provided
        } else {
            self.id = UUID() // Or generate a new one, if applicable
        }
        self.email = email
        self.passwordHash = passwordHash
    }
}


struct UserAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let token = request.headers.bearerAuthorization?.token else {
            throw Abort(.unauthorized, reason: "Missing or invalid token")
        }
        
        // Verify the JWT asynchronously
        let payload = try await request.jwt.verify(token, as: MyJWTPayload.self)
        
        // Query the user based on the JWT payload (e.g., email)
        guard let user = try await User.query(on: request.db)
            .filter(\.$email == payload.subject.value) // or filter based on other payload data
            .first() else {
                throw Abort(.unauthorized, reason: "User not found")
        }
        
        // Log the user in
        request.auth.login(user)
        
        // Proceed with the request lifecycle
        return try await next.respond(to: request)
    }
}



// ----------------------------------------------------- USER INPUT ----------------------------------------------------- \\
struct UserInput: Content {
    let email: String
    let password: String
}

// ----------------------------------------------------- TOKEN RESPONSE  ----------------------------------------------------- \\


struct TokenResponse: Content {
    let token: String
}

