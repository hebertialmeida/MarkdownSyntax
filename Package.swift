// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "MarkdownSyntax",
    platforms: [.macOS(.v10_10), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(name: "MarkdownSyntax", targets: ["MarkdownSyntax"]),
    ],
    dependencies: [
        .package(name: "cmark_gfm", url: "https://github.com/hebertialmeida/swift-cmark-gfm", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(name: "MarkdownSyntax", dependencies: ["cmark_gfm"]),
        .testTarget(name: "MarkdownSyntaxTests", dependencies: ["MarkdownSyntax"]),
    ]
)
