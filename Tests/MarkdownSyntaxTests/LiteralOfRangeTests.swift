//
//  LiteralOfRangeTests.swift
//  MarkdownSyntaxTests
//
//  `ParseContext.literal(of:)`: the text cmark makes of a source range read as text — escapes
//  and entity references resolved — so an extension can search the source for its syntax, keep
//  ranges that are right, and still take the text the reader sees.
//

import Foundation
import XCTest
@testable import MarkdownSyntax

/// Records, for every text node, its source, its literal and `literal(of:)` of its range.
private final class LiteralRecorder: MarkdownExtension, @unchecked Sendable {
    struct Reading: Equatable {
        let source: String
        let literal: String?
        let literalOfRange: String
    }

    let anchors: [NodeKind] = [.text]
    private(set) var readings: [Reading] = []
    /// A range inside the anchor to read too, found by the closure.
    let inner: ((String, Range<String.Index>) -> Range<String.Index>?)?
    private(set) var innerReadings: [String] = []

    init(inner: ((String, Range<String.Index>) -> Range<String.Index>?)? = nil) {
        self.inner = inner
    }

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        guard let range = context.range(of: context.anchor) else { return nil }
        readings.append(Reading(
            source: String(context.source[range]),
            literal: context.anchor.literal,
            literalOfRange: context.literal(of: range)
        ))
        if let inner, let part = inner(context.source, range) {
            innerReadings.append(context.literal(of: part))
        }
        return nil
    }
}

final class LiteralOfRangeTests: XCTestCase {

    private func readings(_ text: String) async throws -> [LiteralRecorder.Reading] {
        let recorder = LiteralRecorder()
        let markdown = try await Markdown(text: text, syntaxExtensions: [recorder])
        _ = await markdown.parse()
        return recorder.readings
    }

    func testEscapesAndEntitiesReadAsCmarkReadsThem() async throws {
        let cases: [(String, String)] = [
            ("a \\_b &eacute; c", "a _b é c"),
            ("&#x41;&#65;&amp;&lt;", "AA&<"),
            ("\\&amp; stays an entity name", "&amp; stays an entity name"),
            ("\\a is no escape", "\\a is no escape"),
            ("&bogus; is no entity", "&bogus; is no entity"),
            ("a trailing \\", "a trailing \\"),
            ("multibyte é \\* ☃ &copy;", "multibyte é * ☃ ©"),
        ]
        for (text, expected) in cases {
            let first = try await readings(text).first
            XCTAssertEqual(first?.literalOfRange, expected, text)
            XCTAssertEqual(first?.literal, expected, "cmark reads \(text) the same way")
        }
    }

    func testPartOfATextNodeReadsOnItsOwn() async throws {
        let recorder = LiteralRecorder { source, range in
            guard let open = source.range(of: "[[", range: range),
                  let close = source.range(of: "]]", range: open.upperBound..<range.upperBound)
            else { return nil }
            return open.upperBound..<close.lowerBound
        }
        let markdown = try await Markdown(text: "see [[Caf&eacute; \\#1]] here", syntaxExtensions: [recorder])
        _ = await markdown.parse()
        XCTAssertEqual(recorder.innerReadings, ["Café #1"])
    }

    func testEscapedPipeInATableCellReadsAsAPipe() async throws {
        let recorder = LiteralRecorder { source, range in
            guard let open = source.range(of: "[[", range: range),
                  let close = source.range(of: "]]", range: open.upperBound..<range.upperBound)
            else { return nil }
            return open.lowerBound..<close.upperBound
        }
        let markdown = try await Markdown(text: "| a |\n|---|\n| see [[Ch#H\\|the h]] here |", syntaxExtensions: [recorder])
        _ = await markdown.parse()
        XCTAssertEqual(recorder.innerReadings, ["[[Ch#H|the h]]"])
    }

    /// Over every text node of documents with escapes, entities and tables, `literal(of:)` of the
    /// node's own range is cmark's literal.
    func testEveryTextNodesRangeReadsAsItsLiteral() async throws {
        let documents = [
            "# Caf&eacute; \\*one\\*\n\nPara with &amp; and \\[x\\] and `code` and *em &lt;*.\n",
            "> quote \\_x\\_ &#x263A;\n>\n> - item &quot;q&quot;\n",
            "| a \\| b | c |\n|---|---|\n| [[C\\|D]] | x \\| y \\| z |\n| &amp; \\| | \\*e\\* |\n",
            "line one\\\nline two &nbsp;end\n",
        ]
        for document in documents {
            for reading in try await readings(document) {
                XCTAssertEqual(reading.literalOfRange, reading.literal, "\(document.debugDescription): text \(reading.source.debugDescription)")
            }
        }
    }
}
