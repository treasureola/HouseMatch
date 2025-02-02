import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor
import JWT


// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    print("gettting the db application...")

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)
    print("got the db the application...")

    await app.jwt.keys.add(hmac: "secret", digestAlgorithm: .sha256)
    print("gettting the todo migration...")

//    app.middleware.use(UserAuthenticator())
// need this for my migration to work
    app.migrations.add(CreateTodo())
    print("gettting the todo user migration...")

    app.migrations.add(CreateUser())
    print("gettting the todo propertymigration...")

    app.migrations.add(CreateProperty())
    
    try await app.autoMigrate()
    // register routes
    try routes(app)
}
