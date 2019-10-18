// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MarkdownSyntax",
    products: [
        .library(name: "MarkdownSyntax", targets: ["MarkdownSyntax"]),
    ],
    dependencies: [
        .package(url: "https://github.com/KristopherGBaker/libcmark_gfm.git", from: "0.29.3"),
    ],
    targets: [
        .target(name: "MarkdownSyntax", dependencies: ["libcmark_gfm"]),
        .testTarget(name: "MarkdownSyntaxTests", dependencies: ["MarkdownSyntax"]),
    ]
)
