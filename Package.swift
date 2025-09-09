// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ekexport",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "ekexport", targets: ["ekexport"])
    ],
    targets: [
        .executableTarget(
            name: "ekexport",
            path: "Sources/ekexport"
        )
    ]
)

