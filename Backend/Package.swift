// swift-tools-version:6.0
import PackageDescription

let package: Package = Package(
    name: "Backend_Property_Listing",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        //  Vapor: A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        
        //  Fluent: ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),

        //  Fluent SQLite Driver (MISSING in your current file)
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.3.0"),
        
        //  SwiftNIO: Non-blocking, event-driven networking.
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        
        //  Leaf: A templating engine for Vapor (if you need it)
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"), // Added this
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Leaf", package: "leaf") // Only if you use Leaf
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v5]
)

// Swift settings
var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
