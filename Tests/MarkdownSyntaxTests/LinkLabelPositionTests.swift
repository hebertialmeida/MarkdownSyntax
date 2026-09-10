import XCTest
@testable import MarkdownSyntax

/// Positions and source classification for links and images.
///
/// Covers three regressions from the swift-cmark migration:
///  1. an inline link whose label is a suffix of its destination was mistaken for a
///     GFM bare autolink and lost its opening `[`;
///  2. angle autolinks were shifted a character to the right, dropping `<`;
///  3. a bare autolink's own child, and the text run in front of it, kept stale
///     positions that overlapped the link.
final class LinkLabelPositionTests: XCTestCase {

    // MARK: Helpers

    private func paragraphChildren(_ input: String) async throws -> [PhrasingContent] {
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        return paragraph?.children ?? []
    }

    private func slice(_ position: Position?, in input: String) -> String? {
        position?.range.map { String(input[$0]) }
    }

    // MARK: Bug 1 — a label that is a suffix of its destination is not an autolink

    func testLinkWithLabelMatchingFragmentKeepsOpeningBracket() async throws {
        // given
        let input = "go [harbor](#harbor) now"

        // when
        let link = try await paragraphChildren(input)[1] as? Link

        // then
        XCTAssertEqual(slice(link?.position, in: input), "[harbor](#harbor)")
        XCTAssertEqual(link?.kind, .inline)
        XCTAssertEqual(slice(link?.labelPosition, in: input), "harbor")
    }

    func testLinkWithHyphenatedLabelMatchingFragmentKeepsOpeningBracket() async throws {
        // given
        let input = "go [chapter-two](#chapter-two) now"

        // when
        let link = try await paragraphChildren(input)[1] as? Link

        // then
        XCTAssertEqual(slice(link?.position, in: input), "[chapter-two](#chapter-two)")
        XCTAssertEqual(link?.kind, .inline)
    }

    func testLinkWithLabelSuffixOfDestinationKeepsOpeningBracket() async throws {
        // given
        let input = "go [example.com](https://example.com) now"

        // when
        let link = try await paragraphChildren(input)[1] as? Link

        // then
        XCTAssertEqual(slice(link?.position, in: input), "[example.com](https://example.com)")
        XCTAssertEqual(link?.kind, .inline)
    }

    func testLinkWithLabelThatIsNotASuffixIsUnaffected() async throws {
        // given
        let input = "go [the harbor](#harbor) now"

        // when
        let link = try await paragraphChildren(input)[1] as? Link

        // then
        XCTAssertEqual(slice(link?.position, in: input), "[the harbor](#harbor)")
        XCTAssertEqual(slice(link?.labelPosition, in: input), "the harbor")
    }

    // MARK: Bug 2 — angle autolinks keep both brackets

    func testAngleAutoLinkInsideParagraphKeepsBrackets() async throws {
        // given
        let input = "angle <https://www.example.com> autolink"

        // when
        let children = try await paragraphChildren(input)
        let link = children[1] as? Link

        // then
        XCTAssertEqual(slice(link?.position, in: input), "<https://www.example.com>")
        XCTAssertEqual(link?.kind, .autolink)
        XCTAssertNil(link?.labelPosition)
        XCTAssertEqual(slice(children[0].position, in: input), "angle ")
        XCTAssertEqual(slice(children[2].position, in: input), " autolink")
    }

    // MARK: Bug 3 — a bare autolink's child and preceding sibling

    func testBareAutoLinkChildAndSiblingDoNotOverlapTheLink() async throws {
        // given
        let input = "bare https://www.example.com autolink"

        // when
        let children = try await paragraphChildren(input)
        let link = children[1] as? Link

        // then
        XCTAssertEqual(slice(link?.position, in: input), "https://www.example.com")
        XCTAssertEqual(link?.kind, .autolink)
        XCTAssertEqual(slice(children[0].position, in: input), "bare ")
        XCTAssertEqual(slice(link?.children.first?.position, in: input), "https://www.example.com")
        XCTAssertEqual(slice(children[2].position, in: input), " autolink")
    }

    func testBareAutoLinkAfterInlineMarkupDoesNotOverlapTheLink() async throws {
        // given
        let input = "a **b** https://www.example.com c"

        // when
        let children = try await paragraphChildren(input)
        let link = children[3] as? Link

        // then
        XCTAssertEqual(slice(children[2].position, in: input), " ")
        XCTAssertEqual(slice(link?.position, in: input), "https://www.example.com")
        XCTAssertEqual(slice(link?.children.first?.position, in: input), "https://www.example.com")
    }

    func testWwwAutoLinkChildMatchesTheLink() async throws {
        // given
        let input = "testing www.example.com is a autolink"

        // when
        let children = try await paragraphChildren(input)
        let link = children[1] as? Link

        // then
        XCTAssertEqual(slice(children[0].position, in: input), "testing ")
        XCTAssertEqual(slice(link?.position, in: input), "www.example.com")
        XCTAssertEqual(slice(link?.children.first?.position, in: input), "www.example.com")
    }

    // MARK: labelPosition

    func testInlineLinkLabelPosition() async throws {
        // given
        let input = "[party](https://google.com)"

        // when
        let link = try await paragraphChildren(input).first as? Link

        // then
        XCTAssertEqual(slice(link?.labelPosition, in: input), "party")
    }

    func testImageLabelPosition() async throws {
        // given
        let input = "![Alice](000003.png)"

        // when
        let image = try await paragraphChildren(input).first as? Image

        // then
        XCTAssertEqual(slice(image?.labelPosition, in: input), "Alice")
    }

    func testLabelPositionSpansNestedMarkup() async throws {
        // given
        let input = "[**bold** label](u)"

        // when
        let link = try await paragraphChildren(input).first as? Link

        // then
        XCTAssertEqual(slice(link?.labelPosition, in: input), "**bold** label")
    }

    func testEmptyLabelHasNoPosition() async throws {
        // given
        let input = "[](u)"

        // when
        let link = try await paragraphChildren(input).first as? Link

        // then
        XCTAssertNotNil(link)
        XCTAssertNil(link?.labelPosition)
    }

    func testEmptyImageLabelHasNoPosition() async throws {
        // given
        let input = "![](u)"

        // when
        let image = try await paragraphChildren(input).first as? Image

        // then
        XCTAssertNotNil(image)
        XCTAssertNil(image?.labelPosition)
    }

    func testAngleAutoLinkHasNoLabelPosition() async throws {
        // given
        let input = "<https://example.com>"

        // when
        let link = try await paragraphChildren(input).first as? Link

        // then
        XCTAssertEqual(link?.kind, .autolink)
        XCTAssertNil(link?.labelPosition)
    }

    func testBareAutoLinkHasNoLabelPosition() async throws {
        // given
        let input = "bare https://www.example.com autolink"

        // when
        let link = try await paragraphChildren(input)[1] as? Link

        // then
        XCTAssertEqual(link?.kind, .autolink)
        XCTAssertNil(link?.labelPosition)
    }

    // MARK: kind

    func testInlineLinkKind() async throws {
        // given
        let input = "[a](u)"

        // when
        let link = try await paragraphChildren(input).first as? Link

        // then
        XCTAssertEqual(link?.kind, .inline)
    }

    func testFullReferenceLinkKind() async throws {
        // given
        let input = "[a][id]\n\n[id]: https://example.com"

        // when
        let link = try await paragraphChildren(input).first as? Link

        // then
        XCTAssertEqual(link?.kind, .reference)
        XCTAssertEqual(slice(link?.position, in: input), "[a][id]")
        XCTAssertEqual(slice(link?.labelPosition, in: input), "a")
    }

    func testShortcutReferenceLinkKind() async throws {
        // given
        let input = "[id]\n\n[id]: https://example.com"

        // when
        let link = try await paragraphChildren(input).first as? Link

        // then
        XCTAssertEqual(link?.kind, .reference)
        XCTAssertEqual(slice(link?.position, in: input), "[id]")
        XCTAssertEqual(slice(link?.labelPosition, in: input), "id")
    }
}
