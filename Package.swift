// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SecureShieldKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SecureShieldKit",
            targets: ["SecureShieldKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SecureShieldKit",
            dependencies: [],
            path: "SecureShieldKit",
            exclude: [
                "SecureShieldKit.xcframework",
                "SecureShieldKit.md"
            ]
        ),
        .testTarget(
            name: "SecureShieldKitTests",
            dependencies: ["SecureShieldKit"],
            path: "SecureShieldKitTests"
        )
    ]
)
