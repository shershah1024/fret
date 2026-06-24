// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "fret",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "fret", targets: ["fret"]),       // CLI / launchd daemon
        .executable(name: "FretApp", targets: ["FretApp"]),  // menu-bar app
        .library(name: "FretCore", targets: ["FretCore"]),
    ],
    targets: [
        .target(name: "FretCore"),
        .executableTarget(name: "fret", dependencies: ["FretCore"]),
        .executableTarget(name: "FretApp", dependencies: ["FretCore"]),
    ]
)
