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
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ekexport",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/ekexport"
        )
    ]
)

