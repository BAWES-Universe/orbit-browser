// swift-tools-version: 6.0
//
// Orbit Browser — macOS shell (Q-ORBIT-01)
// Thin WebKit wrapper hosting the Orbit web-app. Zero browser internals.
//
// Built with the Command Line Tools toolchain only (no Xcode, no xcodebuild):
//   swift build
import PackageDescription

let package = Package(
    name: "OrbitBrowser",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "OrbitBrowser",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("WebKit"),
                .linkedFramework("AppKit"),
            ]
        )
    ]
)
