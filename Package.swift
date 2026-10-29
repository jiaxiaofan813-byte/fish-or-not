// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FishOrNotCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "FishOrNotCore", targets: ["FishOrNotCore"])],
    targets: [
        .target(name: "FishOrNotCore", path: "FishOrNot/Core"),
        .testTarget(name: "FishOrNotCoreTests", dependencies: ["FishOrNotCore"])
    ]
)
