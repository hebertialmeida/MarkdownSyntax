import XCTest
@testable import MarkdownSyntax

final class ContentInlinePositionTests: XCTestCase {

    func testLinkRange() async throws {
        // given
        let input = #"[alpha](https://example.com "bravo")"#

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children.first as? Link
        let range = input.range(0...35)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], #"[alpha](https://example.com "bravo")"#)
    }

    // MARK: GFM autolink

    func testAutoLinkRange() async throws {
        // given
        let input = "testing http://www.example.com is a autolink"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children[1] as? Link
        let range = input.range(8...29)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], "http://www.example.com")
    }

    func testAutoLinkHttpsRange() async throws {
        // given
        let input = "testing https://www.example.com is a autolink"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children[1] as? Link
        let range = input.range(8...30)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], "https://www.example.com")
    }

    func testAutoLinkFtpRange() async throws {
        // given
        let input = "testing ftp://www.example.com is a autolink"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children[1] as? Link
        let range = input.range(8...28)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], "ftp://www.example.com")
    }

    func testWwwAutoLinkRange() async throws {
        // given
        let input = "testing www.example.com is a autolink"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children[1] as? Link
        let range = input.range(8...22)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], "www.example.com")
    }

    // MARK: Native cmark autolink

    func testAutoLinkBracesRange() async throws {
        // given
        let input = "<https://example.com>"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children.first as? Link
        let range = input.range(0...20)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], "<https://example.com>")
    }

    func testLinkWithEmptyChildRange() async throws {
        // given
        let input = "[](https://example.com)"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children.first as? Link
        let range = input.range(0...22)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], "[](https://example.com)")
    }

    func testInternalLinkRange() async throws {
        // given
        let input = "[Page 52](#some-topic)"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children.first as? Link
        let range = input.range(0...21)

        // then
        XCTAssertEqual(link?.position.range, range)
        XCTAssertEqual(input[range], "[Page 52](#some-topic)")
    }

    func testImageRange() async throws {
        // given
        let input = #"![alpha](https://example.com/favicon.ico "bravo")"#

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let image = paragraph?.children.first as? Image
        let range = input.range(0...48)

        // then
        XCTAssertEqual(image?.position.range, range)
        XCTAssertEqual(input[range], #"![alpha](https://example.com/favicon.ico "bravo")"#)
    }

    func testStrikethroughRange() async throws {
        // given
        let input = "~~alpha~~"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let delete = paragraph?.children.first as? Delete
        let range = input.range(0...8)

        // then
        XCTAssertEqual(delete?.position.range, range)
        XCTAssertEqual(input[range], "~~alpha~~")
    }

    func testStrongRange() async throws {
        // given
        let input = "**alpha**"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Strong
        let range = input.range(0...8)

        // then
        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[range], "**alpha**")
    }

    func testStrongUnderscoreRange() async throws {
        // given
        let input = "__alpha__"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Strong
        let range = input.range(0...8)

        // then
        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[range], "__alpha__")
    }

    func testEmphasisRange() async throws {
        // given
        let input = "*alpha*"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Emphasis
        let range = input.range(0...6)

        // then
        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[range], "*alpha*")
    }

    func testEmphasisUnderscoreRange() async throws {
        // given
        let input = "_alpha_"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Emphasis
        let range = input.range(0...6)

        // then
        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[range], "_alpha_")
    }

    func testInlineCodeRange() async throws {
        // given
        let input = "`alpha`"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? InlineCode
        let range = input.range(0...6)

        // then
        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[range], "`alpha`")
    }

    func testInlineCodeRangeMultiBackticks() async throws {
        // given
        let input = "```alpha```"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? InlineCode
        let range = input.range(0...10)

        // then
        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[range], "```alpha```")
    }

    func testSoftBreakRange() async throws {
        // given
        let input = "foo\nbar"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let softBreak = paragraph?.children[1] as? SoftBreak

        // then
        XCTAssertNil(softBreak?.position.range) // Cmark don't return any position for SoftBreak
    }

    func testSpaceLineBreakRange() async throws {
        // given
        let input =
        """
        test
        test
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let lineBreak = paragraph?.children[1] as? Break

        // then
        XCTAssertNil(lineBreak?.position.range) // Cmark don't return any position for LineBreak
    }

    func testFootnoteReferenceRange() async throws {
        // given
        let input =
        """
        Here is a footnote reference,[^1] and another.[^longnote] and some more [^alpha bravo]

        [^1]: Here is the footnote.
        [^longnote]: Here's one with multiple blocks.
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children[1] as? FootnoteReference
        let node2 = paragraph?.children[3] as? FootnoteReference
        let range = input.range(29...32)
        let range2 = input.range(46...56)

        // then
        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[range], "[^1]")
        XCTAssertEqual(node2?.position.range, range2)
        XCTAssertEqual(input[range2], "[^longnote]")
    }

    func testHTMLInlineRange() async throws {
        // given
        let input = "<del>*foo*</del>"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let tag1 = paragraph?.children[0] as? HTML
        let em = paragraph?.children[1] as? Emphasis
        let tag2 = paragraph?.children[2] as? HTML
        let range = input.range(0...4)
        let emRange = input.range(5...9)
        let range2 = input.range(10...15)

        // then
        XCTAssertEqual(tag1?.position.range, range)
        XCTAssertEqual(input[range], "<del>")
        XCTAssertEqual(em?.position.range, emRange)
        XCTAssertEqual(input[emRange], "*foo*")
        XCTAssertEqual(tag2?.position.range, range2)
        XCTAssertEqual(input[range2], "</del>")
    }

    func testHTMLInlineCommentPosition() async throws {
        // given
        let input = "This is some <!-- this --> bla bla bla"

        // when
        let tree = try await Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children[1] as? HTML
        let range = input.range(13...25)

        // then
        XCTAssertEqual(input[node!.position.range!], "<!-- this -->")
        XCTAssertEqual(input[range], "<!-- this -->")
    }
}
