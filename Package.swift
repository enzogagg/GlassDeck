// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GlassDeck",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "GlassDeckMacApp", targets: ["GlassDeckMacApp"]),
        .executable(name: "glassdeck-mac-daemon", targets: ["GlassDeckMacDaemon"]),
    ],
    targets: [
        .executableTarget(
            name: "GlassDeckMacApp",
            path: "mac-app/Sources/GlassDeckMacApp"
        ),
        .executableTarget(
            name: "GlassDeckMacDaemon",
            path: "mac-daemon/Sources/GlassDeckMacDaemon"
        ),
    ]
)
