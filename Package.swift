// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GenerateImageAssets",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "GenerateImageAssetsLib", targets: ["GenerateImageAssetsLib"]),
        .executable(name: "generate-image-assets", targets: ["GenerateImageAssets"]),
    ],
    targets: [
        .target(
            name: "GenerateImageAssetsLib",
            dependencies: []
        ),
        .executableTarget(
            name: "GenerateImageAssets",
            dependencies: ["GenerateImageAssetsLib"]
        ),
    ]
)
