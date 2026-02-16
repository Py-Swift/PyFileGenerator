// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PyFileGenerator",
    platforms: [
        .macOS(.v11),
        .iOS(.v13)
    ],
    products: [
        // Products can be used to vend plugins, making them visible to other packages.
        .plugin(
            name: "PyFileGenerator",
            targets: ["PyFileGenerator"]
        ),
        .plugin(
            name: "SetupPyGenerator",
            targets: ["SetupPyGenerator"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
        .package(url: "https://github.com/Py-Swift/PySwiftAST", from: .init(0, 0, 0)),
        .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: .init(1, 2, 0)),
        .package(url: "https://github.com/Py-Swift/PySwift2Python", from: .init(0, 0, 0))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .plugin(
            name: "PyFileGenerator",
            capability: .command(
                intent: .custom(
                verb: "PyFileGenerator",
                description: """
                generates fake pip module to mimic the module/class 
                structure from a PySwiftWrapper
                """
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "generates pip module")
                ]
            ),
            dependencies: [
                "Generator"
            ]
        ),
        .plugin(
            name: "SetupPyGenerator",
            capability: .command(
                intent: .custom(
                verb: "SetupPyGenerator",
                description: """
                generates fake pip module to mimic the module/class 
                structure from a PySwiftWrapper
                """
                ),
                permissions: [
                    .writeToPackageDirectory(reason: "generates pip module")
                ]
            ),
            dependencies: [
                "Generator"
            ]
        ),
        .executableTarget(
            name: "Generator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                "PathKit",
                .product(name: "PySwiftAST", package: "PySwiftAST"),
                .product(name: "PySwiftCodeGen", package: "PySwiftAST"),
                .product(name: "PyAstVisitors", package: "PySwiftAST"),
                .product(name: "PyFormatters", package: "PySwiftAST"),
                "PySwift2Python"
            ]
        )
    ]
)
