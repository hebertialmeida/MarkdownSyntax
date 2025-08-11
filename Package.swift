// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "MarkdownSyntax",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12), .watchOS(.v4)],
    products: [
        .library(name: "MarkdownSyntax", targets: ["MarkdownSyntax"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hebertialmeida/swift-cmark-gfm", .upToNextMajor(from: "1.1.0"))
    ],
    targets: [
        .target(name: "MarkdownSyntax", dependencies: [.product(name: "cmark_gfm", package: "swift-cmark-gfm")]),
        .testTarget(name: "MarkdownSyntaxTests", dependencies: ["MarkdownSyntax"]),
    ]
)
