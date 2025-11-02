// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LZO",
    platforms: [
        .macOS(.v13), .iOS(.v16)
    ],
    products: [
        .library(
            name: "LZO",
            targets: ["LZO"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LZO",
            dependencies: []
        ),
        .testTarget(
            name: "LZOTests",
            dependencies: [
                "LZO"
            ],
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
