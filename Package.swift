// swift-tools-version:6.0
import PackageDescription

//firebase-admin-swift does NOT exist. The correct Firebase Admin SDK for Swift is not publicly available yet. As an alternative, you can:
//
//Use Firebase REST API directly in your backend.
//Use a third-party Swift package for verifying Firebase tokens.
//Since Firebase does not provide a native server-side Swift SDK, the best approach is to verify Firebase ID tokens manually using Google's public keys.
let package = Package(
    name: "Backend_Property_Search",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        //  Vapor Framework
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        //  Fluent ORM
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        //  Fluent driver for SQLite
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
        //  Swift NIO for async networking
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
            ],
            path: "Sources/App"
        ),
        .executableTarget(
            name: "Run",
            dependencies: ["App"],
            path: "Sources/Run"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
