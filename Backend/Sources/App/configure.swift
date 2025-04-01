import Fluent
import FluentSQLiteDriver
import Vapor

public func configure(_ app: Application) async throws {
    // This is what exposes your server to the internet
    app.http.server.configuration.hostname = "0.0.0.0"
    
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
    app.middleware.use(CORSMiddleware(configuration: .default()))

    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserPreference())

    try await app.autoMigrate()
    try routes(app)
}
