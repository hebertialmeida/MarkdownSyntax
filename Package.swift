// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "MarkdownSyntax",
    products: [
        .library(name: "MarkdownSyntax", targets: ["MarkdownSyntax"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hebertialmeida/swift-cmark-gfm.git", .branch("master"))
    ],
    targets: [
        .target(name: "MarkdownSyntax", dependencies: ["cmark_gfm"]),
        .testTarget(name: "MarkdownSyntaxTests", dependencies: ["MarkdownSyntax"]),
    ]
)
