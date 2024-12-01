import Vapor
import Fluent
import JWT

// Define the routes
func routes(_ app: Application) throws {
    // User Registration
    app.post("register") { req async throws -> HTTPStatus in
        let userInput = try req.content.decode(UserInput.self)
        let passwordHash = try Bcrypt.hash(userInput.password)

        let newUser = User(email: userInput.email, passwordHash: passwordHash)

        if let _ = try await User.query(on: req.db)
            .filter(\.$email == newUser.email)
            .first() {
            throw Abort(.conflict, reason: "Email already exists")
        }

        try await newUser.save(on: req.db)
        return .ok
    }

    // User Login
    app.post("login") { req async throws -> TokenResponse in
        let loginInput = try req.content.decode(UserInput.self)

        guard let user = try await User.query(on: req.db)
            .filter(\.$email == loginInput.email)
            .first(),
              try Bcrypt.verify(loginInput.password, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        let payload = MyJWTPayload(
            subject: .init(value: user.email),
            expiration: .init(value: .distantFuture)
        )

        let token = try await req.jwt.sign(payload)  // Fixed with `await`
        return TokenResponse(token: token)
    }

    // Protected route that requires authentication
    app.get("protected") { req async throws -> String in
        return "You are authenticated"
    }
}
