import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor
import JWT


// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
    
    await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)

//    app.middleware.use(UserAuthenticator())
// need this for my migration to work
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateProperty())
    
    try await app.autoMigrate()
    // register routes
    try routes(app)
}
