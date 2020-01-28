// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MarkdownSyntax",
    platforms: [.macOS(.v10_10), .iOS(.v8), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .library(name: "MarkdownSyntax", targets: ["MarkdownSyntax"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hebertialmeida/swift-cmark-gfm", .branch("master"))
    ],
    targets: [
        .target(name: "MarkdownSyntax", dependencies: ["cmark_gfm"]),
        .testTarget(name: "MarkdownSyntaxTests", dependencies: ["MarkdownSyntax"]),
    ]
)
