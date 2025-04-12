import Fluent
import Vapor

final class Property: Model, Content, @unchecked Sendable {
    static let schema = "properties"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "city")
    var city: String

    @Field(key: "property_type")
    var propertyType: String

    @Field(key: "price")
    var price: Int

    @Field(key: "bedrooms")
    var bedrooms: Int

    @Field(key: "bathrooms")
    var bathrooms: Int

    @Field(key: "square_feet")
    var squareFeet: Int

    init() {}

    init(
        id: UUID? = nil,
        city: String,
        propertyType: String,
        price: Int,
        bedrooms: Int,
        bathrooms: Int,
        squareFeet: Int
    ) {
        self.id = id
        self.city = city
        self.propertyType = propertyType
        self.price = price
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.squareFeet = squareFeet
    }
}
