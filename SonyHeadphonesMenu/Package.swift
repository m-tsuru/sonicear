// swift-tools-version: 6.2
import PackageDescription

let mdrLibSearchPath = "../build/libmdr/src"
let mdrPlatformLibSearchPath = "../build/libmdr/src/Platform/MacOS"
let fmtLibSearchPath = "../build/_deps/fmt-build"

let package = Package(
    name: "SonyHeadphonesMenu",
    platforms: [.macOS(.v26)],
    targets: [
        .target(
            name: "CMDRBridge",
            path: "Sources/CMDRBridge",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "SonyHeadphonesMenu",
            dependencies: ["CMDRBridge"],
            path: "Sources/SonyHeadphonesMenu",
            swiftSettings: [.swiftLanguageMode(.v6)],
            linkerSettings: [
                .unsafeFlags([
                    "-L\(mdrLibSearchPath)",
                    "-L\(mdrPlatformLibSearchPath)",
                    "-L\(fmtLibSearchPath)",
                ]),
                .linkedLibrary("mdr"),
                .linkedLibrary("mdr_PlatformMacOS"),
                .linkedLibrary("fmt"),
                .linkedLibrary("c++"),
                .linkedFramework("IOBluetooth"),
                .linkedFramework("Foundation"),
            ]
        ),
    ]
)
