import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) async throws {
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
    app.middleware.use(CORSMiddleware(configuration: .default()))

    app.migrations.add(CreateUser())
//    app.migrations.add(CreateProperty())
//    Needed to communicate with the frontend functionality
    // Important for creating the user preference
    app.migrations.add(CreateUserPreference())


    try await app.autoMigrate()

    try routes(app)
}
