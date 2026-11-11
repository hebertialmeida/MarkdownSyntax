// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "MarkdownSyntax",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(name: "MarkdownSyntax", targets: ["MarkdownSyntax"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark", .upToNextMajor(from: "0.8.0"))
    ],
    targets: [
        .target(
            name: "MarkdownSyntax",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
            ]
        ),
        // `swift run -c release Benchmarks` times the parser over generated fixtures.
        // Not a product, so packages that depend on MarkdownSyntax never build it.
        .executableTarget(name: "Benchmarks", dependencies: ["MarkdownSyntax"]),
        .testTarget(
            name: "MarkdownSyntaxTests",
            dependencies: ["MarkdownSyntax"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
