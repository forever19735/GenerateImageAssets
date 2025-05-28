// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GenerateImageAssets",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "GenerateImageAssetsLib", targets: ["GenerateImageAssetsLib"]),
        .executable(name: "generate-image-assets", targets: ["GenerateImageAssets"]),
    ],
    targets: [
        .target(name: "GenerateImageAssetsLib"),
        .executableTarget(
            name: "GenerateImageAssets",
            dependencies: ["GenerateImageAssetsLib"]
        ),
    ]
)
