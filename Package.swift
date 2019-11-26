// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ProfileService",
    products: [
        .library(name: "ProfileService", targets: ["App"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        // 🔵 Swift ORM (queries, models, relations, etc) built on PostgreSQL.
        .package(url: "https://github.com/plarson/fluent-postgis.git", .branch("master")),
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentPostGIS", "Vapor"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

