// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clipboard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Clipboard", targets: ["Clipboard"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.2")
    ],
    targets: [
        .executableTarget(
            name: "Clipboard",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Clipboard",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "ClipboardTests",
            dependencies: ["Clipboard"],
            path: "Tests/ClipboardTests"
        )
    ]
)
