// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShizukuKeyAuth",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "ShizukuKeyAuth", targets: ["ShizukuKeyAuth"])
    ],
    targets: [
        .target(name: "ShizukuKeyAuth"),
        .testTarget(name: "ShizukuKeyAuthTests", dependencies: ["ShizukuKeyAuth"])
    ]
)
