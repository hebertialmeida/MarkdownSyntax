import XCTest
@testable import MarkdownSyntax

/// GFM bare autolinks on a paragraph's **second and later lines**.
///
/// The autolink extension reports a bare URL's start as an offset into the paragraph's content
/// buffer rather than a column on its line. On a single-line paragraph the two coincide to within
/// one character, so a `+1` fudge looked correct; after a soft line break the error grows by every
/// byte of the preceding lines, and highlighting painted only a *suffix* of each URL.
///
/// The end is reported correctly throughout, so these pin the start being derived from it.
final class BareAutolinkLineOffsetTests: XCTestCase {

    private func links(in input: String) async throws -> [Link] {
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        return (paragraph?.children.compactMap { $0 as? Link }) ?? []
    }

    private func slice(_ input: String, _ node: Node) -> String? {
        node.position.range.map { String(input[$0]) }
    }

    // MARK: The regression

    func testABareAutolinkAfterASoftBreakSpansTheWholeURL() async throws {
        let input = "first line\nhttps://www.example.com bare after softbreak"

        let found = try await links(in: input)

        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(slice(input, found[0]), "https://www.example.com")
    }

    func testTheSecondLinkOnALineAfterASoftBreakIsNotTruncated() async throws {
        // The reported case: an angle autolink and a bare one on the same wrapped line. The bare
        // one used to come back as ".example.com".
        let input = "first line\n<https://www.example.com> and https://www.example.com"

        let found = try await links(in: input)

        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(slice(input, found[0]), "<https://www.example.com>")
        XCTAssertEqual(slice(input, found[1]), "https://www.example.com")
    }

    func testTwoBareAutolinksAfterASoftBreak() async throws {
        // The error grows with the preceding lines, so both links on line 2 are wrong by the same
        // amount — and neither is wrong by one.
        let input = "line one\na https://one.example.com and https://two.example.com b"

        let found = try await links(in: input)

        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(slice(input, found[0]), "https://one.example.com")
        XCTAssertEqual(slice(input, found[1]), "https://two.example.com")
    }

    func testTheErrorGrowsWithTheParagraphSoALaterLineIsAlsoRight() async throws {
        let input = "one\ntwo\nthree\nfour\nfive https://www.example.com six"

        let found = try await links(in: input)

        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(slice(input, found[0]), "https://www.example.com")
        XCTAssertEqual(found[0].position.start.line, 5)
    }

    func testAWwwAutolinkIsMeasuredBySourceLengthNotItsExpandedDestination() async throws {
        // GFM expands www.example.com to http://www.example.com, so measuring against the
        // destination would walk back too far.
        let input = "first line\nsee www.example.com now"

        let found = try await links(in: input)

        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(slice(input, found[0]), "www.example.com")
        XCTAssertEqual(found[0].url.absoluteString, "http://www.example.com")
    }

    // MARK: The text nodes around it

    func testTheAutolinksOwnChildSpansTheSameRangeAsTheLink() async throws {
        let input = "line one\na https://one.example.com and https://two.example.com b"

        let found = try await links(in: input)
        let child = found[0].children.first

        XCTAssertEqual(slice(input, child!), "https://one.example.com")
        XCTAssertEqual(child?.position.range, found[0].position.range)
    }

    func testTheTextRunInFrontOfALaterLineAutolinkStopsBeforeIt() async throws {
        // Its literal is "a " but its reported span was seven columns wide, overlapping the URL.
        let input = "line one\na https://one.example.com and https://two.example.com b"

        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let leading = paragraph?.children.compactMap { $0 as? Text }.first { $0.value == "a " }

        XCTAssertEqual(slice(input, leading!), "a ")
    }

    // MARK: A URL that opens a paragraph

    func testABareAutolinkThatOpensTheDocumentIsMapped() async throws {
        // cmark reports start column 0 here, so `position(in:)` mapped nothing at all and the URL
        // was not highlighted anywhere. The end is still sound, so the start comes from it.
        let input = "https://www.example.com opens the paragraph"

        let found = try await links(in: input)

        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(slice(input, found[0]), "https://www.example.com")
    }

    func testABareAutolinkThatOpensALaterParagraphIsMapped() async throws {
        let input = "para one\n\nhttps://www.example.com opens the second"

        let tree = try await Markdown(text: input).parse()
        let second = tree.children.compactMap { $0 as? Paragraph }.last
        let link = second?.children.compactMap { $0 as? Link }.first

        XCTAssertNotNil(link)
        XCTAssertEqual(slice(input, link!), "https://www.example.com")
        XCTAssertEqual(link?.position.start.line, 3)
    }

    func testAWwwAutolinkThatOpensTheDocumentIsMapped() async throws {
        let input = "www.example.com opens it"

        let found = try await links(in: input)

        XCTAssertEqual(slice(input, found[0]), "www.example.com")
    }

    func testTheChildOfAParagraphOpeningAutolinkIsMappedToo() async throws {
        let input = "https://www.example.com opens the paragraph"

        let found = try await links(in: input)
        let child = found[0].children.first

        XCTAssertNotNil(child)
        XCTAssertEqual(slice(input, child!), "https://www.example.com")
        XCTAssertEqual(child?.position.range, found[0].position.range)
    }

    // MARK: Still right where it already was

    func testASingleLineParagraphIsUnchanged() async throws {
        let input = "a https://one.example.com and https://two.example.com b"

        let found = try await links(in: input)

        XCTAssertEqual(found.count, 2)
        XCTAssertEqual(slice(input, found[0]), "https://one.example.com")
        XCTAssertEqual(slice(input, found[1]), "https://two.example.com")
    }

    func testAnAngleAutolinkAfterASoftBreakKeepsItsBrackets() async throws {
        let input = "first line\n<https://www.example.com> tail"

        let found = try await links(in: input)

        XCTAssertEqual(slice(input, found[0]), "<https://www.example.com>")
    }

    func testAnInlineLinkAfterASoftBreakIsUntouched() async throws {
        let input = "first line\nsee [harbor](#harbor) now"

        let found = try await links(in: input)

        XCTAssertEqual(found[0].kind, .inline)
        XCTAssertEqual(slice(input, found[0]), "[harbor](#harbor)")
        XCTAssertEqual(found[0].labelPosition?.range.map { String(input[$0]) }, "harbor")
    }
}
