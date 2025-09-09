// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ekexport",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ekexport", targets: ["ekexport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/tbartelmess/swift-ical.git", from: "0.0.7"),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.2.5")
    ],
    targets: [
        .target(
            name: "EkExportCore",
            dependencies: [
                .product(name: "SwiftIcal", package: "swift-ical")
            ],
            path: "Sources/EkExportCore"
        ),
        .executableTarget(
            name: "ekexport",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                "EkExportCore"
            ],
            path: "Sources/ekexport"
        )
    ]
)
