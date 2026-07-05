// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlassDeckMacApp",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "GlassDeckMacApp", targets: ["GlassDeckMacApp"])
    ],
    targets: [
        .executableTarget(name: "GlassDeckMacApp")
    ]
)
