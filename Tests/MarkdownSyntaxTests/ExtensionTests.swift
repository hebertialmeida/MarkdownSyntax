//
//  ExtensionTests.swift
//  MarkdownSyntaxTests
//
//  Syntax extensions: recognized in the one tree build, by anchor type, with ranges read from
//  the source, `plain` equal to the tree without the extension, and HTML rendered by cmark
//  through custom nodes that leave the cmark tree as it was.
//

import Foundation
import XCTest
@testable import MarkdownSyntax

final class ExtensionTests: XCTestCase {

    // MARK: No extension, or one that recognizes nothing: the same tree (AC-01)

    func testTreeIsUnchangedWithNoExtensionOrOneThatRecognizesNothing() async throws {
        let directory = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        for name in ["generated-4k", "generated-64k", "generated-128k"] {
            let source = try String(contentsOf: directory.appendingPathComponent("\(name).md"), encoding: .utf8)
            for ending in LineEnding.allCases {
                let text = ending.apply(to: source)
                let expected = TreeDump.dump(try await Markdown(text: text).parse(), in: text)
                let expectedHTML = try await Markdown(text: text).renderHtml()

                for extensions: [MarkdownExtension] in [[], [RejectingExtension()]] {
                    let markdown = try await Markdown(text: text, syntaxExtensions: extensions)
                    let label = "\(name).\(ending.rawValue) with \(extensions.map { "\(type(of: $0))" })"
                    let tree = await markdown.parse()
                    let html = try await markdown.renderHtml()
                    XCTAssertEqual(TreeDump.dump(tree, in: text), expected, label)
                    XCTAssertEqual(html, expectedHTML, label)
                }
            }
        }
    }

    func testAnExtensionIsOfferedOnlyItsAnchorTypes() async throws {
        let recorder = AnchorRecorder(anchors: [.blockquote, .inlineCode])
        _ = try await Markdown(text: "Text `code`\n\n> quote `more`\n\n```\nblock\n```\n", syntaxExtensions: [recorder]).parse()
        XCTAssertEqual(recorder.offered, ["inlineCode", "blockquote", "inlineCode"])
    }

    func testFrameKindsAreNeverOfferedAndAnAnchorReadsItsParentsKind() async throws {
        let frames = AnchorRecorder(anchors: [.root, .listItem, .tableRow, .tableCell, .footnoteDefinition])
        let source = "- item\n\n| a |\n|---|\n| b |\n\nNote[^1]\n\n[^1]: The note.\n"
        _ = try await Markdown(text: source, syntaxExtensions: [frames]).parse()
        XCTAssertEqual(frames.offered, [])

        let paragraphs = ParentRecorder(anchors: [.paragraph])
        _ = try await Markdown(text: "Top\n\n- item\n\n> quoted\n", syntaxExtensions: [paragraphs]).parse()
        XCTAssertEqual(paragraphs.parents, [.root, .listItem, .blockquote])
    }

    func testEveryKindReadsBackFromItsCmarkType() {
        for kind in NodeKind.allCases {
            XCTAssertEqual(NodeKind(kind.cmarkType), kind, "\(kind)")
        }
        XCTAssertNil(NodeKind(.customBlock))
        XCTAssertNil(NodeKind(.customInline))
    }

    func testExtensionsSharingAnAnchorAreTriedInOrderAndTheFirstMatchWins() async throws {
        let source = "a ==b== c"
        let first = try await Markdown(text: source, syntaxExtensions: [HighlightExtension(), ShoutExtension()]).parse()
        XCTAssertEqual(collect(Highlight.self, in: first).count, 1)
        XCTAssertTrue(collect(Shout.self, in: first).isEmpty)

        // The first returns nil for this text node, so the second is offered it.
        let second = try await Markdown(text: "LOUD", syntaxExtensions: [HighlightExtension(), ShoutExtension()]).parse()
        XCTAssertEqual(collect(Shout.self, in: second).count, 1)
    }

    func testWithExtensionsTheTreeIsBuiltOnceAndEveryParseReturnsIt() async throws {
        let source = "Note[^1] ==b==\n\n[^1]: The note.\n"
        let markdown = try await Markdown(text: source, syntaxExtensions: [HighlightExtension()])
        let first = await markdown.parse()
        let second = await markdown.parse()
        XCTAssertEqual(TreeDump.dump(second, in: source), TreeDump.dump(first, in: source))
        XCTAssertEqual(collect(FootnoteDefinition.self, in: second).map(\.label), ["1"])
    }

    // MARK: Ranges from the source (AC-02)

    func testInlineExtensionRangesAreTheWrittenSyntaxWithMultibyteTextBeforeAndInside() async throws {
        let source = "Café — ==naïve 😀 text== and ==日本==."
        let tree = try await Markdown(text: source, syntaxExtensions: [HighlightExtension()]).parse()
        let marks = collect(Highlight.self, in: tree)

        XCTAssertEqual(marks.map { written($0.position, in: source) }, ["==naïve 😀 text==", "==日本=="])
        XCTAssertEqual(marks.map { written($0.contentPosition, in: source) }, ["naïve 😀 text", "日本"])
        XCTAssertEqual(marks.map { $0.subpositions["contentPosition"] }, marks.map(\.contentPosition))
        XCTAssertEqual(marks.map { ($0.children.first as? Text)?.value }, ["naïve 😀 text", "日本"])

        // The text around the marks keeps its own ranges.
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let texts = paragraph.children.compactMap { $0 as? Text }
        XCTAssertEqual(texts.map(\.value), ["Café — ", " and ", "."])
        XCTAssertEqual(texts.map { written($0.position, in: source) }, ["Café — ", " and ", "."])
    }

    func testInlineExtensionRangesInListsQuotesAndOnALastLineWithNoNewline() async throws {
        for ending in LineEnding.allCases {
            let source = ending.apply(to: "- item ==one==\n  - nested ==two==\n\n> quoted ==three==\n> > deeper ==four==\n\nlast ==five==")
            let tree = try await Markdown(text: source, syntaxExtensions: [HighlightExtension()]).parse()
            let marks = collect(Highlight.self, in: tree)
            XCTAssertEqual(
                marks.map { written($0.position, in: source) },
                ["==one==", "==two==", "==three==", "==four==", "==five=="],
                ending.rawValue
            )
            XCTAssertEqual(marks.map { written($0.contentPosition, in: source) }, ["one", "two", "three", "four", "five"], ending.rawValue)
            // Lines and columns are the ones every node in the tree uses.
            XCTAssertEqual(marks.last?.position.start.line, 7, ending.rawValue)
            XCTAssertEqual(marks.last?.position.start.column, 6, ending.rawValue)
            XCTAssertEqual(marks.last?.position.end.column, 13, ending.rawValue)
        }
    }

    func testBlockExtensionClaimsTheSiblingAfterItsAnchor() async throws {
        let source = "Intro.\n\nListing: Hello, wörld\n\n```swift\nprint(\"hi\")\n```\n\nAfter."
        let tree = try await Markdown(text: source, syntaxExtensions: [ListingExtension()]).parse()

        XCTAssertEqual(tree.children.count, 3)
        let listing = try XCTUnwrap(tree.children[1] as? Listing)
        XCTAssertEqual(written(listing.position, in: source), "Listing: Hello, wörld\n\n```swift\nprint(\"hi\")\n```")
        XCTAssertEqual(written(listing.markerPosition, in: source), "Listing:")
        XCTAssertEqual(listing.code.value, "print(\"hi\")\n")
        XCTAssertEqual(listing.code.language, "swift")
        XCTAssertEqual((tree.children[2] as? Paragraph).map { written($0.position, in: source) }, "After.")
    }

    func testBlockExtensionLeavesItsAnchorAloneWhenTheSiblingIsMissing() async throws {
        let source = "Listing: no code after\n\nJust text."
        let markdown = try await Markdown(text: source, syntaxExtensions: [ListingExtension()])
        let tree = await markdown.parse()
        let without = try await Markdown(text: source).parse()
        XCTAssertEqual(TreeDump.dump(tree, in: source), TreeDump.dump(without, in: source))
    }

    // MARK: Syntax cmark reads as something else makes no node (AC-04)

    func testNoExtensionNodeInCodeHTMLOrEscapedSyntax() async throws {
        let sources = [
            "A code span `==not==` here.",
            "```\n==not==\n```",
            "    ==not== indented",
            "<div>\n==not==\n</div>",
            "Escaped \\==not== here.",
            "Escaped \\Listing: no\n\n```\ncode\n```",
            "An entity &#61;=not== here.",
        ]
        for source in sources {
            let markdown = try await Markdown(text: source, syntaxExtensions: [HighlightExtension(), ListingExtension()])
            let tree = await markdown.parse()
            XCTAssertTrue(collect(Highlight.self, in: tree).isEmpty, source)
            XCTAssertTrue(collect(Listing.self, in: tree).isEmpty, source)
            let html = try await markdown.renderHtml()
            let expected = try await Markdown(text: source).renderHtml()
            XCTAssertEqual(html, expected, source)
        }
    }

    // MARK: A reader that doesn't know an extension reads `plain` (AC-05)

    func testPlainOfABlockExtensionIsTheTreeWithoutIt() async throws {
        let source = "> Listing: In a quote\n>\n> ```\n> code\n> ```\n\nEnd."
        let with = try await Markdown(text: source, syntaxExtensions: [ListingExtension()]).parse()
        XCTAssertEqual(collect(Listing.self, in: with).count, 1)
        let without = try await Markdown(text: source).parse()
        XCTAssertEqual(TreeDump.dump(UnknownExtensionReader.read(with), in: source), TreeDump.dump(without, in: source))
    }

    func testPlainOfAnInlineExtensionReadsAsTheSameText() async throws {
        let source = "Some ==marked== and ==more== text\n\n- a ==b== c"
        let with = try await Markdown(text: source, syntaxExtensions: [HighlightExtension()]).parse()
        let without = try await Markdown(text: source).parse()
        let read = UnknownExtensionReader.read(with)

        // cmark's one text node reads as the same text over the same source, in several nodes.
        XCTAssertEqual(texts(in: read).map(\.value).joined(), texts(in: without).map(\.value).joined())
        XCTAssertEqual(
            texts(in: read).map { written($0.position, in: source) }.joined(),
            texts(in: without).map { written($0.position, in: source) }.joined()
        )
        XCTAssertEqual(collect(Highlight.self, in: with).map { $0.plain.compactMap { ($0 as? Text)?.value } }, [["==marked=="], ["==more=="], ["==b=="]])
    }

    func testALinkLabelKeepsStaticExtensionNodesAndReadsOthersAsPlain() async throws {
        let source = "[a ==b== c](https://example.com) and [LOUD](https://example.com)"
        let tree = try await Markdown(text: source, syntaxExtensions: [HighlightExtension(), ShoutExtension()]).parse()
        let links = collect(Link.self, in: tree)
        XCTAssertEqual(links.count, 2)
        XCTAssertEqual(links.first?.children.compactMap { $0 as? Highlight }.count, 1)
        // `Shout` isn't static phrasing content, so inside a link it reads as its plain text.
        XCTAssertEqual(links.last?.children.compactMap { ($0 as? Text)?.value }, ["LOUD"])
    }

    // MARK: HTML through cmark custom nodes (1.2)

    func testHTMLHasTheExtensionMarkupWhetherOrNotParseRanFirst() async throws {
        let source = "Some ==marked== text, ==twice==.\n\nListing: Hi\n\n```\ncode\n```\n"
        let expected = "<p>Some <mark>marked</mark> text, <mark>twice</mark>.</p>\n<figure class=\"listing\">\n<p>Listing: Hi</p>\n<pre><code>code\n</code></pre>\n</figure>\n"

        let rendered = try await Markdown(text: source, options: [], syntaxExtensions: [HighlightExtension(), ListingExtension()]).renderHtml()
        XCTAssertEqual(rendered, expected)

        let parsedFirst = try await Markdown(text: source, options: [], syntaxExtensions: [HighlightExtension(), ListingExtension()])
        _ = await parsedFirst.parse()
        let afterParse = try await parsedFirst.renderHtml()
        let again = try await parsedFirst.renderHtml()
        XCTAssertEqual(afterParse, expected)
        XCTAssertEqual(again, expected, "a second render is the same")
    }

    func testRenderingHTMLLeavesTheCmarkTreeAsCmarkMadeIt() async throws {
        let source = "> Some ==marked== text\n\nListing: Hi\n\n```\ncode\n```\n"
        let plain = try await Markdown(text: source)
        let markdown = try await Markdown(text: source, syntaxExtensions: [HighlightExtension(), ListingExtension()])
        _ = try await markdown.renderHtml()

        let (xml, plainXml) = (try await markdown.renderXml(), try await plain.renderXml())
        let (commonMark, plainCommonMark) = (try await markdown.renderCommonMark(width: 0), try await plain.renderCommonMark(width: 0))
        XCTAssertEqual(xml, plainXml)
        XCTAssertEqual(commonMark, plainCommonMark)
    }

    func testHTMLIsLeftToCmarkWhereACustomNodeCantGo() async throws {
        // A GFM table cell can't hold a custom inline node: the tree has the extension's node,
        // the HTML is cmark's own.
        let source = "| a |\n|---|\n| ==b== |\n"
        let markdown = try await Markdown(text: source, syntaxExtensions: [HighlightExtension()])
        let tree = await markdown.parse()
        let (html, expected) = (try await markdown.renderHtml(), try await Markdown(text: source).renderHtml())
        XCTAssertEqual(collect(Highlight.self, in: tree).count, 1)
        XCTAssertEqual(html, expected)
    }

    func testAWrappedParagraphInATightListRendersAsThoughTheCustomNodeWereItsParent() async throws {
        // As the HTML article says: cmark reads a paragraph's tightness from its grandparent.
        let html = try await Markdown(text: "- a\n- b\n", options: [], syntaxExtensions: [DivExtension()]).renderHtml()
        XCTAssertEqual(html, "<ul>\n<li>\n<div>\n<p>a</p>\n</div>\n</li>\n<li>\n<div>\n<p>b</p>\n</div>\n</li>\n</ul>\n")
    }

    func testTheHTMLIsBuiltOnlyWhenTheDocumentRenders() async throws {
        // A parse that never renders, such as an editor's, builds none of the markup (D-14).
        let source = "Some ==marked== text.\n\nA paragraph.\n"
        let built = HTMLCounter()
        let markdown = try await Markdown(text: source, options: [], syntaxExtensions: [CountingExtension(built: built)])
        _ = await markdown.parse()
        XCTAssertEqual(built.count, 0, "parsed, not rendered: no markup built")

        let html = try await markdown.renderHtml()
        XCTAssertEqual(html, "<div>\n<p>Some <mark>marked</mark> text.</p>\n</div>\n<div>\n<p>A paragraph.</p>\n</div>\n")
        XCTAssertEqual(built.count, 6, "each wrap's onEnter and onExit, once per render")
    }

    func testARecognizerThatReturnsNilLeavesNoClaimAndNoHTML() async throws {
        let source = "Listing: x\n\n```\ncode\n```\n\nText ==b==."
        let markdown = try await Markdown(text: source, syntaxExtensions: [RejectingExtension(claimAndWrap: true)])
        let plain = try await Markdown(text: source)
        let (tree, plainTree) = (await markdown.parse(), await plain.parse())
        let (html, plainHTML) = (try await markdown.renderHtml(), try await plain.renderHtml())
        XCTAssertEqual(TreeDump.dump(tree, in: source), TreeDump.dump(plainTree, in: source))
        XCTAssertEqual(html, plainHTML)
    }

    // MARK: Helpers

    private func written(_ position: Position, in source: String) -> String {
        guard let range = position.range else { return "<no range>" }
        return String(source[range])
    }

    private func texts(in node: Node) -> [Text] {
        collect(Text.self, in: node)
    }
}

/// Every node of a type in a tree, in order, not looking inside `plain`.
func collect<T>(_ type: T.Type, in node: Node) -> [T] {
    var found: [T] = []
    for case let (label?, value) in Mirror(reflecting: node).children where label != "plain" {
        guard let nodes = value as? [Node] else { continue }
        for child in nodes {
            if let match = child as? T { found.append(match) }
            found += collect(type, in: child)
        }
    }
    return found
}

/// Reads a tree as a reader that knows no extension: every extension node as its `plain`.
enum UnknownExtensionReader {

    static func read(_ root: Root) -> Root {
        Root(children: expand(root.children), position: root.position)
    }

    private static func expand(_ nodes: [Content]) -> [Content] {
        nodes.flatMap { node -> [Content] in
            if let node = node as? ExtensionContent { return expand(node.plain) }
            return [rebuild(node)]
        }
    }

    private static func blocks(_ nodes: [BlockContent]) -> [BlockContent] {
        expand(nodes).compactMap { $0 as? BlockContent }
    }

    private static func phrasing(_ nodes: [PhrasingContent]) -> [PhrasingContent] {
        expand(nodes).compactMap { $0 as? PhrasingContent }
    }

    private static func rebuild(_ node: Content) -> Content {
        switch node {
        case let node as Blockquote: return Blockquote(children: blocks(node.children), position: node.position)
        case let node as Paragraph: return Paragraph(children: phrasing(node.children), position: node.position)
        case let node as Heading: return Heading(children: phrasing(node.children), depth: node.depth, position: node.position)
        case let node as List:
            let items = node.children.compactMap { $0 as? ListItem }.map {
                ListItem(checked: $0.checked, spread: $0.spread, children: blocks($0.children), position: $0.position) as ListContent
            }
            return List(ordered: node.ordered, start: node.start, spread: node.spread, children: items, position: node.position)
        default: return node
        }
    }
}

/// Offered every anchor kind; reads each anchor, and with `claimAndWrap` claims the next sibling
/// and asks for HTML, then returns nil.
private struct RejectingExtension: MarkdownExtension {
    var claimAndWrap = false

    let anchors = NodeKind.allCases

    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]? {
        _ = context.plainBlock(context.anchor)
        if claimAndWrap {
            if let next = context.nextUnclaimed { context.claim(through: next) }
            context.wrapHTML(onEnter: "<x>", onExit: "</x>")
        }
        return nil
    }

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        _ = context.plainPhrasing(context.anchor)
        if claimAndWrap {
            if let next = context.nextUnclaimed { context.claim(through: next) }
            context.wrapHTML(onEnter: "<y>", onExit: "</y>")
        }
        return nil
    }
}

/// Records the kind of every anchor it is offered.
private final class AnchorRecorder: MarkdownExtension, @unchecked Sendable {
    let anchors: [NodeKind]
    private(set) var offered: [String] = []

    init(anchors: [NodeKind]) {
        self.anchors = anchors
    }

    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]? {
        offered.append(context.anchor.kind.map { "\($0)" } ?? "nil")
        return nil
    }

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        offered.append(context.anchor.kind.map { "\($0)" } ?? "nil")
        return nil
    }
}

/// Records the kind of each anchor's parent.
private final class ParentRecorder: MarkdownExtension, @unchecked Sendable {
    let anchors: [NodeKind]
    private(set) var parents: [NodeKind?] = []

    init(anchors: [NodeKind]) {
        self.anchors = anchors
    }

    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]? {
        parents.append(context.anchor.parent?.kind)
        return nil
    }
}

/// A text node written in capitals, as interactive (not static) phrasing content.
private struct Shout: PhrasingContent, ExtensionContent {
    let position: Position
    let plain: [Content]
}

private struct ShoutExtension: MarkdownExtension {
    let anchors: [NodeKind] = [.text]

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        guard
            let literal = context.anchor.literal, !literal.isEmpty,
            literal == literal.uppercased(),
            let text = context.plainPhrasing(context.anchor)
        else { return nil }
        return [Shout(position: context.position(of: context.anchor), plain: [text])]
    }
}

/// Counts the markup a ``CountingExtension`` builds.
private final class HTMLCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var built = 0

    var count: Int { lock.withLock { built } }

    func markup(_ text: String) -> String {
        lock.withLock { built += 1 }
        return text
    }
}

/// Wraps every paragraph in a `<div>` and every `==…==` in a `<mark>`, counting each piece of
/// markup as it is built.
private struct CountingExtension: MarkdownExtension {
    let built: HTMLCounter
    var anchors: [NodeKind] { [.paragraph, .text] }

    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]? {
        guard let paragraph = context.plainBlock(context.anchor) else { return nil }
        context.wrapHTML(onEnter: built.markup("<div>"), onExit: built.markup("</div>"))
        return [paragraph]
    }

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        let source = context.source
        guard
            let range = context.range(of: context.anchor),
            let open = source.range(of: "==", range: range),
            let close = source.range(of: "==", range: open.upperBound..<range.upperBound),
            let text = context.plainPhrasing(context.anchor)
        else { return nil }
        context.wrapHTML(open.upperBound..<close.lowerBound, in: open.lowerBound..<close.upperBound,
                         onEnter: built.markup("<mark>"), onExit: built.markup("</mark>"))
        return [text]
    }
}

/// Renders every paragraph inside a `<div>`, and keeps it as it is in the tree.
private struct DivExtension: MarkdownExtension {
    let anchors: [NodeKind] = [.paragraph]

    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]? {
        guard let paragraph = context.plainBlock(context.anchor) else { return nil }
        context.wrapHTML(onEnter: "<div>", onExit: "</div>")
        return [paragraph]
    }
}
