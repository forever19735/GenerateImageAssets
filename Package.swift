// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GenerateImageAssets",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "generate-image-assets", targets: ["GenerateImageAssets"]),
        .library(name: "GenerateImageAssetsLib", targets: ["GenerateImageAssetsLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2")
    ],
    targets: [
        .target(
            name: "GenerateImageAssetsLib",
            dependencies: []
        ),
        .executableTarget(
            name: "GenerateImageAssets",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "GenerateImageAssetsLib"
            ]
        ),
        .testTarget(
            name: "GenerateImageAssetsLibTests",
            dependencies: ["GenerateImageAssetsLib"]
        )
    ]
)

