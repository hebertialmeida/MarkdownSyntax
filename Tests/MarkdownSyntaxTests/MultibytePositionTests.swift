//
//  MultibytePositionTests.swift
//  MarkdownSyntaxTests
//
//  Safety-harness coverage: byte-vs-character position correctness.
//
//  cmark reports source positions in *byte* (UTF-8) columns. `CMNode.position(in:using:)`
//  builds `String.Index`es via `text.utf8.index(...)`, so the stored `Position.range`
//  should slice the *correct substring* even when the input contains multibyte
//  characters. The pre-existing position tests only assert against `input.range(0...N)`,
//  where N is a *Character* offset — that coincides with the byte offset only for ASCII,
//  so those tests are structurally blind to multibyte mapping errors.
//
//  These tests assert the substring the range maps to (`input[range] == expected`),
//  never a numeric offset. If any of these fail, the byte/character mapping is a real
//  latent bug (not a test bug) and must be reported, not worked around.
//

import XCTest
@testable import MarkdownSyntax

final class MultibytePositionTests: XCTestCase {

    // MARK: - Emoji (4-byte scalars)

    func testEmphasisAfterEmoji() async throws {
        // "😀" is 1 Character but 4 UTF-8 bytes; the strong delimiters follow it.
        let input = "😀 **bold** tail"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let range = try XCTUnwrap(strong.position.range)

        XCTAssertEqual(String(input[range]), "**bold**")
    }

    func testLinkAfterEmoji() async throws {
        let input = "😀😀 [alpha](https://example.com)"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let link = try XCTUnwrap(paragraph.children.first(where: { $0 is Link }) as? Link)
        let range = try XCTUnwrap(link.position.range)

        XCTAssertEqual(String(input[range]), "[alpha](https://example.com)")
    }

    func testInlineCodeContainingEmoji() async throws {
        let input = "before `x = 😀` after"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let code = try XCTUnwrap(paragraph.children.first(where: { $0 is InlineCode }) as? InlineCode)
        let range = try XCTUnwrap(code.position.range)

        XCTAssertEqual(String(input[range]), "`x = 😀`")
    }

    // MARK: - CJK (3-byte scalars)

    func testEmphasisAfterCJK() async throws {
        // Each of 日本語 is 3 UTF-8 bytes; strong follows.
        let input = "日本語 **太字** です"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let range = try XCTUnwrap(strong.position.range)

        XCTAssertEqual(String(input[range]), "**太字**")
    }

    func testHeadingWithCJK() async throws {
        let input = "# 日本語のテスト"

        let tree = try await Markdown(text: input).parse()
        let heading = try XCTUnwrap(tree.children.first as? Heading)
        let range = try XCTUnwrap(heading.position.range)

        XCTAssertEqual(String(input[range]), "# 日本語のテスト")
    }

    func testCJKTextNodeSubstring() async throws {
        let input = "日本語 **太字**"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let text = try XCTUnwrap(paragraph.children.first as? Text)
        let range = try XCTUnwrap(text.position.range)

        // The leading text node holds "日本語 " (trailing space before the strong).
        XCTAssertEqual(String(input[range]), "日本語 ")
    }

    // MARK: - Accented / precomposed (2-byte scalars)

    func testEmphasisAfterAccented() async throws {
        // café résumé — precomposed é (U+00E9, 2 bytes).
        let input = "café résumé **gras**"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let range = try XCTUnwrap(strong.position.range)

        XCTAssertEqual(String(input[range]), "**gras**")
    }

    // MARK: - Combining marks (grapheme = multiple scalars)

    func testEmphasisAfterCombiningMark() async throws {
        // "cafe" + combining acute over the final e => 1 grapheme, 2 scalars, 3 bytes for "é".
        let input = "cafe\u{0301} **gras**"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let range = try XCTUnwrap(strong.position.range)

        XCTAssertEqual(String(input[range]), "**gras**")
    }

    // MARK: - Emoji with ZWJ sequences (grapheme = many scalars)

    func testEmphasisAfterZWJEmoji() async throws {
        // Family emoji: multiple scalars joined by ZWJ, a single grapheme, 18 UTF-8 bytes.
        let input = "👨‍👩‍👧 **bold**"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let range = try XCTUnwrap(strong.position.range)

        XCTAssertEqual(String(input[range]), "**bold**")
    }

    // MARK: - CRLF line endings

    func testEmphasisOnSecondCRLFLine() async throws {
        let input = "first line\r\n**bold** here"

        let tree = try await Markdown(text: input).parse()
        // Two paragraphs? No — a soft break keeps them in one paragraph.
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let range = try XCTUnwrap(strong.position.range)

        XCTAssertEqual(String(input[range]), "**bold**")
    }

    func testHeadingAfterCRLF() async throws {
        let input = "para\r\n\r\n# Heading"

        let tree = try await Markdown(text: input).parse()
        let heading = try XCTUnwrap(tree.children.first(where: { $0 is Heading }) as? Heading)
        let range = try XCTUnwrap(heading.position.range)

        XCTAssertEqual(String(input[range]), "# Heading")
    }

    // MARK: - Tabs

    func testEmphasisAfterTab() async throws {
        // A leading run of text with a tab then a strong span.
        let input = "a\tb **bold**"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let range = try XCTUnwrap(strong.position.range)

        XCTAssertEqual(String(input[range]), "**bold**")
    }

    // MARK: - Combined: multibyte + link title round-trip on a later line

    // MARK: - Node ENDING on a multibyte character (closed-range end offset)
    //
    // `Position.range` is a *closed* range `start...end`, where `end` is derived from
    // cmark's end_column (byte column of the last character). When that last character
    // is multibyte, the UTF-8 index lands on the first byte of the final grapheme; the
    // closed-range subscript must still include the whole final character.

    func testTextNodeEndingInEmoji() async throws {
        let input = "hello 😀"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let text = try XCTUnwrap(paragraph.children.first as? Text)
        let range = try XCTUnwrap(text.position.range)

        XCTAssertEqual(String(input[range]), "hello 😀")
    }

    func testTextNodeEndingInCJK() async throws {
        let input = "hello 日本語"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let text = try XCTUnwrap(paragraph.children.first as? Text)
        let range = try XCTUnwrap(text.position.range)

        XCTAssertEqual(String(input[range]), "hello 日本語")
    }

    func testHeadingEndingInEmoji() async throws {
        let input = "# done 😀"

        let tree = try await Markdown(text: input).parse()
        let heading = try XCTUnwrap(tree.children.first as? Heading)
        let range = try XCTUnwrap(heading.position.range)

        XCTAssertEqual(String(input[range]), "# done 😀")
    }

    func testStrongEndingInCJK() async throws {
        // Strong span whose inner content ends in a CJK char before the closing "**".
        let input = "start **太字** end"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let strong = try XCTUnwrap(paragraph.children.first(where: { $0 is Strong }) as? Strong)
        let innerText = try XCTUnwrap(strong.children.first as? Text)
        let range = try XCTUnwrap(innerText.position.range)

        XCTAssertEqual(String(input[range]), "太字")
    }

    func testInlineCodeEndingInCJK() async throws {
        let input = "x `コード`"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.first as? Paragraph)
        let code = try XCTUnwrap(paragraph.children.first(where: { $0 is InlineCode }) as? InlineCode)
        let range = try XCTUnwrap(code.position.range)

        XCTAssertEqual(String(input[range]), "`コード`")
    }

    func testLinkOnSecondLineAfterMultibyte() async throws {
        let input = "日本語😀\n[alpha](https://example.com \"t\")"

        let tree = try await Markdown(text: input).parse()
        let paragraph = try XCTUnwrap(tree.children.last as? Paragraph)
        let link = try XCTUnwrap(paragraph.children.first(where: { $0 is Link }) as? Link)
        let range = try XCTUnwrap(link.position.range)

        XCTAssertEqual(String(input[range]), "[alpha](https://example.com \"t\")")
    }
}
