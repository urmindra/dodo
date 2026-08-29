// swift-tools-version: 6.0
import Foundation
import PackageDescription

/// Command Line Tools ship Swift Testing, but SPM does not pass the plugin path or
/// rpath unless we add them. Xcode CI already has these, so we only inject when the
/// CLT files exist.
let commandLineTestingPluginDirectory =
    "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing"
let commandLineTestingFrameworks =
    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
let commandLineTestingInterop =
    "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"

var testSwiftSettings: [SwiftSetting] = []
var testLinkerSettings: [LinkerSetting] = []

if FileManager.default.fileExists(atPath: commandLineTestingPluginDirectory) {
    testSwiftSettings.append(
        .unsafeFlags([
            "-plugin-path", commandLineTestingPluginDirectory
        ])
    )
}

if FileManager.default.fileExists(atPath: commandLineTestingFrameworks) {
    testLinkerSettings.append(
        .unsafeFlags([
            "-Xlinker", "-rpath",
            "-Xlinker", commandLineTestingFrameworks
        ])
    )
}

if FileManager.default.fileExists(atPath: commandLineTestingInterop) {
    testLinkerSettings.append(
        .unsafeFlags([
            "-Xlinker", "-rpath",
            "-Xlinker", commandLineTestingInterop
        ])
    )
}

let package = Package(
    name: "DodoCore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "DodoCore", targets: ["DodoCore"])
    ],
    targets: [
        .target(name: "DodoCore"),
        .testTarget(
            name: "DodoCoreTests",
            dependencies: ["DodoCore"],
            swiftSettings: testSwiftSettings,
            linkerSettings: testLinkerSettings
        )
    ]
)
