// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "KeyboardLockSpike",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "KeyboardLockSpike",
            path: "Sources"
        )
    ]
)
