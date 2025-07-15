// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftXIDExamples",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        // Use the local SwiftXID package
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "SwiftXIDExamples",
            dependencies: [
                .product(name: "SwiftXID", package: "swift-xid")
            ],
            path: ".",
            sources: ["Examples.swift"]
        )
    ]
)
