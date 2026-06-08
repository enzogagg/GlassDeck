// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlassDeckMacDaemon",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "glassdeck-mac-daemon", targets: ["GlassDeckMacDaemon"])
    ],
    targets: [
        .executableTarget(name: "GlassDeckMacDaemon")
    ]
)
