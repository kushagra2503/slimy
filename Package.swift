// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Slimy",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0")
    ],
    targets: [
        .executableTarget(
            name: "Slimy",
            dependencies: [
                .product(name: "Swifter", package: "swifter"),
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
