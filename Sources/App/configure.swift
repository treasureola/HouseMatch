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

   // app.middleware.use(UserAuthenticator()) // Can not have this here as it prevents my code from being run since we are attaching an authentication to every route even those that doesnt need the authentication which should not happen 

    app.migrations.add(CreateTodo())
    try await app.autoMigrate()
    // register routes
    try routes(app)
}
