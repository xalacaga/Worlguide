// swift-tools-version:5.9
import PackageDescription

// See docs/adr/0006-testing-strategy-and-ci-gate.md: both platforms are
// declared so `swift test` runs on macOS without a simulator. Modules must
// therefore avoid UIKit/AVFoundation-only APIs in their public interface —
// that boundary is enforced by review, not by the compiler.
let package = Package(
    name: "WorldGuide",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "WGCore", targets: ["WGCore"]),
        .library(name: "WGConfiguration", targets: ["WGConfiguration"]),
        .library(name: "WGPOI", targets: ["WGPOI"]),
        .library(name: "WGContent", targets: ["WGContent"]),
        .library(name: "WGPlayback", targets: ["WGPlayback"]),
        .library(name: "WGLocation", targets: ["WGLocation"]),
        .library(name: "WGWeather", targets: ["WGWeather"]),
        .library(name: "WGAdapters", targets: ["WGAdapters"]),
    ],
    targets: [
        .target(name: "WGCore"),
        .target(name: "WGConfiguration", dependencies: ["WGCore"]),
        .target(name: "WGPOI", dependencies: ["WGCore"]),
        .target(name: "WGContent", dependencies: ["WGCore"]),
        .target(name: "WGPlayback", dependencies: ["WGCore"]),
        .target(name: "WGLocation", dependencies: ["WGCore"]),
        .target(name: "WGWeather", dependencies: ["WGCore"]),
        // The only module allowed to import a network client (docs/adr/0003,
        // docs/adr/0012) — real adapters for Wikidata/Wikipedia/OSM live here.
        .target(name: "WGAdapters", dependencies: ["WGCore", "WGPOI", "WGContent", "WGWeather", "WGLocation"]),

        .testTarget(name: "WGCoreTests", dependencies: ["WGCore"]),
        .testTarget(name: "WGPOITests", dependencies: ["WGPOI"]),
        .testTarget(name: "WGContentTests", dependencies: ["WGContent"]),
        .testTarget(name: "WGPlaybackTests", dependencies: ["WGPlayback"]),
        .testTarget(name: "WGLocationTests", dependencies: ["WGLocation"]),
        .testTarget(name: "WGWeatherTests", dependencies: ["WGWeather"]),
        .testTarget(name: "WGAdaptersTests", dependencies: ["WGAdapters"]),
    ]
)
