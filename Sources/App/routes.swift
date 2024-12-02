import Vapor
import Fluent
import JWT

// Issouf DIarrassouba =--> Adding the routes

// Define the routes
func routes(_ app: Application) throws {
//    NEED TO ADD THE UTHENTICATION PROTECTION TO THE DIFFERENT ROUTES THAT NEED IT
    let protected = app.grouped(UserAuthenticator())
    // Protected route that requires authentication
    protected.get("protected") { req async throws -> String in
        return "You are authenticated"
    }
    
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


//    Sendable Conformance:
    
//    Sendable ensures thread safety in Swift’s concurrency model. Adding the constraint T: Sendable makes it clear that the items in PaginatedResponse are concurrency-safe.
//    Content and Sendable:

//    All Vapor models (like Property) already conform to Content but might not conform to Sendable. To ensure smooth usage, verify or add Sendable conformance to your Property model.
    struct PaginatedResponse<T: Content & Sendable>: Content, Sendable {
        let items: [T]
        let total: Int
        let page: Int
        let per: Int
    }
    
    enum SearchResponse: Content {
        case paginated(PaginatedResponse<Property>)
        case all([Property])
    }

    
    app.get("search") { req async throws -> SearchResponse in
        // Decode pagination parameters (optional)
        let page = try? req.query.get(Int.self, at: "page")
        let per = try? req.query.get(Int.self, at: "per")

        // Decode search parameters
        let searchRequest = try req.query.decode(PropertySearchRequest.self)

        // Build the base query
        var query = Property.query(on: req.db)
        if let city = searchRequest.city {
            query = query.filter(\.$city == city)
        }
        if let state = searchRequest.state {
            query = query.filter(\.$state == state)
        }
        if let minPrice = searchRequest.minPrice {
            query = query.filter(\.$price >= minPrice)
        }
        if let maxPrice = searchRequest.maxPrice {
            query = query.filter(\.$price <= maxPrice)
        }
        if let propertyType = searchRequest.propertyType {
            query = query.filter(\.$propertyType == propertyType)
        }
        if let capacity = searchRequest.capacity {
            query = query.filter(\.$capacity >= capacity)
        }

        // Handle paginated or non-paginated response
        if let page = page, let per = per {
            // Paginated Response
            let total = try await query.count()
            let properties = try await query
                .range((page - 1) * per..<page * per)
                .all()
            return .paginated(PaginatedResponse(items: properties, total: total, page: page, per: per))
        } else {
            // Non-Paginated Response
            let properties = try await query.all()
            return .all(properties)
        }
    }
    // Database Works
    app.post("seed") { req -> EventLoopFuture<HTTPStatus> in
        let properties = [
            Property(name: "Luxury Villa", city: " New York City", state: "New York",   price: 1000, propertyType: "Villa", capacity: 5, amenities: ["Pool", "WiFi"], isAvailable: true),
            Property(name: "Cozy Apartment", city: "California", state: "Los Angeles", price: 500, propertyType: "Apartment", capacity: 2, amenities: ["WiFi", "Parking"], isAvailable: true),
        ]
        return properties.map { $0.save(on: req.db) }.flatten(on: req.eventLoop).transform(to: .ok)
    }

}
