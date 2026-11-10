//
//  ReadmeExampleTests.swift
//  MarkdownSyntaxTests
//
//  The README's "Extending the syntax" example, and the same example in the documentation
//  catalog, are the code in `ExampleExtensions.swift` word for word, and produce the tree and the
//  HTML they document.
//

import Foundation
import XCTest
@testable import MarkdownSyntax

final class ReadmeExampleTests: XCTestCase {

    private static let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    func testReadmeAndCatalogExamplesAreTheTestedCode() throws {
        let tested = try String(contentsOf: Self.root.appendingPathComponent("Tests/MarkdownSyntaxTests/ExampleExtensions.swift"), encoding: .utf8)
        let example = try XCTUnwrap(
            tested.components(separatedBy: "// README example begin\n").dropFirst().first?
                .components(separatedBy: "// README example end").first
        )

        for file in ["README.md", "Sources/MarkdownSyntax/MarkdownSyntax.docc/ExtendingTheSyntax.md"] {
            let text = try String(contentsOf: Self.root.appendingPathComponent(file), encoding: .utf8)
            let blocks = text.components(separatedBy: "```swift\n").dropFirst().compactMap { $0.components(separatedBy: "\n```").first }
            XCTAssertTrue(blocks.contains(example.trimmingCharacters(in: .newlines)), "\(file) has the example in ExampleExtensions.swift, word for word")
        }
    }

    func testReadmeExampleProducesTheDocumentedTreeAndHTML() async throws {
        let markdown = try await Markdown(text: "Some ==marked== text", syntaxExtensions: [HighlightExtension()])
        let tree = await markdown.parse()
        let html = try await markdown.renderHtml()

        // Root > Paragraph > [Text "Some ", Highlight > [Text "marked"], Text " text"]
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        XCTAssertEqual(tree.children.count, 1)
        XCTAssertEqual(paragraph.children.count, 3)
        XCTAssertEqual((paragraph.children[0] as? Text)?.value, "Some ")
        let highlight = try XCTUnwrap(paragraph.children[1] as? Highlight)
        XCTAssertEqual(highlight.children.compactMap { ($0 as? Text)?.value }, ["marked"])
        XCTAssertEqual((paragraph.children[2] as? Text)?.value, " text")

        XCTAssertEqual(html, "<p data-sourcepos=\"1:1-1:20\">Some <mark>marked</mark> text</p>\n")
    }
}
