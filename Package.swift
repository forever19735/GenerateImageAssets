// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GenerateImageAssets",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "generate-image-assets",
            targets: ["GenerateImageAssets"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "GenerateImageAssets"
        ),
        .testTarget(
            name: "GenerateImageAssetsTests",
            dependencies: ["GenerateImageAssets"]
        ),
    ]
)
