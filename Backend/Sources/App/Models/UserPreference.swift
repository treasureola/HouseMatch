import Fluent
import Vapor

final class UserPreference: Model, Content {
    static let schema = "user_preferences"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "location")
    var location: String

    @Field(key: "property_type")
    var propertyType: String

    @Field(key: "min_price")
    var minPrice: Int

    @Field(key: "max_price")
    var maxPrice: Int

    @Field(key: "bedrooms")
    var bedrooms: Int

    @Field(key: "bathrooms")
    var bathrooms: Int

    @Field(key: "square_feet")
    var squareFeet: Int

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        location: String,
        propertyType: String,
        minPrice: Int,
        maxPrice: Int,
        bedrooms: Int,
        bathrooms: Int,
        squareFeet: Int
    ) {
        self.id = id
        self.$user.id = userID
        self.location = location
        self.propertyType = propertyType
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.squareFeet = squareFeet
    }

    func update(from input: UserPreference) {
        self.location = input.location
        self.propertyType = input.propertyType
        self.minPrice = input.minPrice
        self.maxPrice = input.maxPrice
        self.bedrooms = input.bedrooms
        self.bathrooms = input.bathrooms
        self.squareFeet = input.squareFeet
    }
}

// Allow safe usage in async contexts
extension UserPreference: @unchecked Sendable {}
 
