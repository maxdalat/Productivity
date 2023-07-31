// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Productivity",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Productivity",
            targets: ["Productivity"]),
    ],
    dependencies: [
        // Add the Starscream dependency here
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Productivity",
            dependencies: ["Starscream"]),
        .testTarget(
            name: "ProductivityTests",
            dependencies: ["Productivity"]),
    ]
)
