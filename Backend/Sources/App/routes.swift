import Vapor
import Fluent

func routes(_ app: Application) throws {
    // MARK: - Protected Routes (Firebase Auth Required)
    let protected = app.grouped(FirebaseAuthMiddleware())

    protected.get("protected") { req async throws -> String in
        let user = try req.auth.require(FirebaseUser.self)
        return "You are authenticated as \(user.email)"
    }

    // MARK: - User Registration
    app.post("register") { req async throws -> HTTPStatus in
        let input = try req.content.decode(RegisterInput.self)

        if let _ = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() {
            throw Abort(.conflict, reason: "Email already exists")
        }

        let user = User(
            email: input.email,
            firstName: input.firstName,
            lastName: input.lastName
        )
        try await user.save(on: req.db)
        return .ok
    }

    // MARK: - User Preferences (Save & Get)
    protected.group("preferences") { preferences in
        preferences.get { req async throws -> UserPreference in
            let user = try req.auth.require(User.self)

            guard let preference = try await UserPreference.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first() else {
                throw Abort(.notFound, reason: "Preferences not found")
            }

            return preference
        }

        preferences.post { req async throws -> HTTPStatus in
            let user = try req.auth.require(User.self)
            let newPreference = try req.content.decode(UserPreference.self)

            if let existing = try await UserPreference.query(on: req.db)
                .filter(\.$user.$id == user.requireID())
                .first() {
                existing.update(from: newPreference)
                try await existing.save(on: req.db)
                return .ok
            } else {
                let preference = UserPreference(
                    userID: try user.requireID(),
                    location: newPreference.location,
                    propertyType: newPreference.propertyType,
                    minPrice: newPreference.minPrice,
                    maxPrice: newPreference.maxPrice,
                    bedrooms: newPreference.bedrooms,
                    bathrooms: newPreference.bathrooms,
                    squareFeet: newPreference.squareFeet
                )
                try await preference.save(on: req.db)
                return .created
            }
        }
    }

    // MARK: - Fetch Properties Matching Preferences
    protected.get("match-properties") { req async throws -> [Property] in
        let user = try req.auth.require(User.self)

        guard let preference = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .first() else {
            throw Abort(.notFound, reason: "No preferences found for this user.")
        }

        return try await Property.query(on: req.db)
            .filter(\.$city == preference.location)
            .filter(\.$propertyType == preference.propertyType)
            .filter(\.$price >= Int(preference.minPrice))
            .filter(\.$price <= Int(preference.maxPrice))
            .filter(\.$bedrooms >= preference.bedrooms)
            .filter(\.$bathrooms >= preference.bathrooms)
            .filter(\.$squareFeet >= Int(preference.squareFeet))
            .all()
    }
}
