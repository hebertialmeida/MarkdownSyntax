//
//  AttachedSyntaxTests.swift
//  MarkdownSyntaxTests
//
//  Syntax written right after a node and belonging to it — an attribute block after an image,
//  `![Fox](fox.png){width=50%}` — claimed with the siblings cmark read it into, and left out of
//  the HTML with `omitHTML(_:)`; and the HTML of nodes of the tree, `renderHtml(of:)`, such as an
//  image's label set as a caption, without parsing it again.
//

import Foundation
import XCTest
@testable import MarkdownSyntax

/// An image and the `{…}` written right after it.
struct AttributedImage: StaticPhrasingContent, ExtensionContent {
    let image: Image
    /// The block as written, braces included.
    let attributes: String
    /// The text the last sibling claimed holds after the `}`.
    let rest: Text?
    let position: Position
    let plain: [Content]
}

/// Recognizes a `{…}` written right after an image, through the first `}`, and leaves it out of
/// the HTML.
struct AttributedImageExtension: MarkdownExtension {
    let anchors: [NodeKind] = [.image]

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        let source = context.source
        guard
            let image = context.plainPhrasing(context.anchor) as? Image,
            let imageRange = context.range(of: context.anchor),
            source[imageRange.upperBound...].first == "{",
            let close = source[imageRange.upperBound...].firstIndex(of: "}")
        else { return nil }
        let syntax = imageRange.upperBound..<source.index(after: close)

        // Claim the siblings the block was read into, through the one it ends in. A soft line
        // break has no place of its own: it is claimed with the sibling after it.
        var last: (node: SourceNode, range: Range<String.Index>)?
        var cursor = context.nextUnclaimed
        while let next = cursor {
            if let range = context.range(of: next) {
                guard range.lowerBound < syntax.upperBound else { break }
                context.claim(through: next)
                last = (next, range)
            }
            cursor = next.next
        }
        let plain: [Content] = [image] + context.claimed.compactMap { context.plainPhrasing($0) }
        guard let last, context.omitHTML(syntax) else { return nil }
        let rest = last.range.upperBound > syntax.upperBound
            ? context.position(of: syntax.upperBound..<last.range.upperBound).map { Text(value: String(source[syntax.upperBound..<last.range.upperBound]), position: $0) }
            : nil
        guard let position = context.position(of: imageRange.lowerBound..<syntax.upperBound) else { return nil }
        return [AttributedImage(image: image, attributes: String(source[syntax]), rest: rest, position: position, plain: plain)]
    }
}

/// Offers `{…}` after an image to 1.5.0's split, as a recognizer anchored on the text would:
/// records whether it took it.
final class SplitProbe: MarkdownExtension, @unchecked Sendable {
    let anchors: [NodeKind] = [.text]
    private let lock = NSLock()
    private var taken: [Bool] = []
    var results: [Bool] { lock.withLock { taken } }

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        guard context.anchor.previous?.kind == .image, let range = context.range(of: context.anchor),
              context.source[range].first == "{" else { return nil }
        let source = context.source
        let close = source[range.lowerBound...].firstIndex(of: "}") ?? range.upperBound
        let syntax = range.lowerBound..<min(source.index(after: close), source.endIndex)
        var through = context.anchor
        while let next = through.next, let nextRange = context.range(of: next), nextRange.lowerBound < syntax.upperBound {
            context.claim(through: next)
            through = next
        }
        let took = context.wrapHTML(syntax.lowerBound..<syntax.lowerBound, in: syntax, onEnter: "", onExit: "")
        lock.withLock { taken.append(took) }
        return nil
    }
}

final class AttachedSyntaxTests: XCTestCase {

    /// HTML without source positions, which differ where the block is taken out of the source.
    private static let options: CMDocumentOption = [.strikethroughDoubleTilde, .footnotes]

    /// Each case, and the source as it reads with its block taken out.
    private let cases: [(name: String, source: String, without: String)] = [
        ("plain", "![Fox](fox.png){width=50%} runs\n", "![Fox](fox.png) runs\n"),
        ("alone", "![Fox](fox.png){width=50%}\n", "![Fox](fox.png)\n"),
        ("entity", "![Fox](fox.png){alt=\"a &amp; b\"} runs\n", "![Fox](fox.png) runs\n"),
        ("escape", "![Fox](fox.png){alt=\"a \\\"b\\\"\"} runs\n", "![Fox](fox.png) runs\n"),
        ("emphasis", "![Fox](fox.png){alt=\"*red* fox\"} runs\n", "![Fox](fox.png) runs\n"),
        ("link", "![Fox](fox.png){alt=\"[a](b)\"} runs\n", "![Fox](fox.png) runs\n"),
        ("line break", "![Fox](fox.png){alt=\"a\nb\"} runs\n", "![Fox](fox.png) runs\n"),
        ("table cell", "| a |\n|---|\n| ![Fox](fox.png){width=50%} b |\n", "| a |\n|---|\n| ![Fox](fox.png) b |\n"),
        ("link label", "[![Fox](fox.png){width=50%}](https://example.com)\n", "[![Fox](fox.png)](https://example.com)\n"),
        ("quote", "> ![Fox](fox.png){alt=\"a\n> b\"} runs\n", "> ![Fox](fox.png) runs\n"),
        ("multibyte", "Ünïcödé ![Föx](fox.png){alt=\"ç\"} 日本\n", "Ünïcödé ![Föx](fox.png) 日本\n"),
    ]

    func testSplitTakesOnlyABlockOfPlainTextOutsideATableCell() async throws {
        // The spike (0060, M5): a text-anchored split can't leave the block out where an entity,
        // an escape or emphasis is inside it, or in a table cell.
        let expected: [String: Bool] = [
            "plain": true, "alone": true, "entity": false, "escape": false, "emphasis": false, "link": false,
            "line break": false, "table cell": false, "link label": true, "quote": false, "multibyte": true,
        ]
        for item in cases {
            let probe = SplitProbe()
            _ = try await Markdown(text: item.source, syntaxExtensions: [probe]).parse()
            XCTAssertEqual(probe.results, [try XCTUnwrap(expected[item.name])], item.name)
        }
    }

    func testOmittedSyntaxRendersAsTheSourceWithoutIt() async throws {
        for item in cases {
            let markdown = try await Markdown(text: item.source, options: Self.options, syntaxExtensions: [AttributedImageExtension()])
            let tree = await markdown.parse()
            let html = try await markdown.renderHtml()
            let expected = try await Markdown(text: item.without, options: Self.options).renderHtml()
            XCTAssertEqual(html, expected, item.name)
            XCTAssertEqual(collect(AttributedImage.self, in: tree).count, 1, item.name)
            // Rendered twice, the same: the tree is cmark's own again after each render.
            let again = try await markdown.renderHtml()
            let (xml, plainXml) = (try await markdown.renderXml(), try await Markdown(text: item.source, options: Self.options).renderXml())
            XCTAssertEqual(again, html, item.name)
            XCTAssertEqual(xml, plainXml, item.name)
        }
    }

    func testTheNodeHoldsItsBlockAsWrittenAndThePlainReadingWhole() async throws {
        let source = "![Fox](fox.png){alt=\"*red* &amp;\"} runs\n"
        let tree = try await Markdown(text: source, syntaxExtensions: [AttributedImageExtension()]).parse()
        let node = try XCTUnwrap(collect(AttributedImage.self, in: tree).first)
        XCTAssertEqual(node.attributes, "{alt=\"*red* &amp;\"}")
        XCTAssertEqual(node.rest?.value, " runs")
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        XCTAssertEqual(paragraph.children.count, 1)
        // `plain` is the tree with no extension: the image, then every sibling the block was in.
        let plainTree = try await Markdown(text: source).parse()
        let plainParagraph = try XCTUnwrap(plainTree.children.first as? Paragraph)
        XCTAssertEqual(node.plain.count, plainParagraph.children.count)
    }

    func testOmitIsRefusedWhereTheSyntaxDoesNotLineUpWithTheSiblings() async throws {
        // The block ends inside emphasis that runs past it: nothing to leave out cleanly.
        let source = "![Fox](fox.png){alt=\"*a\"} b*\n"
        let markdown = try await Markdown(text: source, syntaxExtensions: [AttributedImageExtension()])
        let tree = await markdown.parse()
        let (html, expected) = (try await markdown.renderHtml(), try await Markdown(text: source).renderHtml())
        XCTAssertTrue(collect(AttributedImage.self, in: tree).isEmpty)
        XCTAssertEqual(html, expected)
    }

    func testRenderHtmlOfNodesIsCmarksHTMLOfThem() async throws {
        let source = "Before ![A *red* `fox` &amp; [more](m)](fox.png) after\n\n| a |\n|---|\n| ![**b**](b.png) |\n"
        for extensions: [MarkdownExtension] in [[], [AttributedImageExtension()]] {
            let markdown = try await Markdown(text: source, syntaxExtensions: extensions)
            let tree = await markdown.parse()
            let images = collect(Image.self, in: tree)
            XCTAssertEqual(images.count, 2)
            let first = try await markdown.renderHtml(of: images[0].children)
            let second = try await markdown.renderHtml(of: images[1].children)
            let none = try await markdown.renderHtml(of: [])
            XCTAssertEqual(first, "A <em>red</em> <code>fox</code> &amp; <a href=\"m\">more</a>")
            XCTAssertEqual(second, "<strong>b</strong>")
            XCTAssertEqual(none, "")
        }
    }

    func testRenderHtmlOfANodeFromAnotherTreeThrows() async throws {
        let other = try await Markdown(text: "elsewhere\n").parse()
        let markdown = try await Markdown(text: "here\n")
        do {
            _ = try await markdown.renderHtml(of: other.children)
            XCTFail("A node of another tree has no place in this one")
        } catch {
            XCTAssertEqual(error as? CMDocumentError, .renderError)
        }
    }

    func testRenderHtmlOfAnExtensionsNodeIsItsPlainNodes() async throws {
        let source = "![Fox](fox.png){width=50%} runs\n"
        let markdown = try await Markdown(text: source, syntaxExtensions: [AttributedImageExtension()])
        let tree = await markdown.parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let html = try await markdown.renderHtml(of: paragraph.children)
        XCTAssertEqual(html, "<img src=\"fox.png\" alt=\"Fox\" />{width=50%} runs")
    }
}
