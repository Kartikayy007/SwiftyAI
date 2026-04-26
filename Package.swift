// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftyAI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "SwiftyAI", targets: ["SwiftyAI"]),
    ],
    targets: [
        .target(
            name: "SwiftyAI",
            path: "Swifty AI",
            exclude: ["Swifty_AI.docc"]
        ),
    ]
)
