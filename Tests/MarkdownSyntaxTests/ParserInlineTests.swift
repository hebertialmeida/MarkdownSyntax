import XCTest
@testable import MarkdownSyntax

final class ParserInlineTests: XCTestCase {

    func testLink() throws {
        // given
        let input = #"[alpha](https://example.com "bravo")"#

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children.first as? Link
        let linkText = link?.children.first as? Text

        // then
        XCTAssertEqual(link?.url.absoluteString, "https://example.com")
        XCTAssertEqual(link?.title, "bravo")
        XCTAssertEqual(linkText?.value, "alpha")
    }

    // Fixes https://github.com/commonmark/commonmark.js/issues/177
    func testInvalidLink() throws {
        // given
        let input = """
        [link](/u(ri )
        [link](/u(ri
        )
        """

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let child0 = paragraph?.children[0] as? Text
        let child1 = paragraph?.children[1] as? SoftBreak
        let child2 = paragraph?.children[2] as? Text
        let child3 = paragraph?.children[3] as? SoftBreak
        let child4 = paragraph?.children[4] as? Text

        // then
        XCTAssertEqual(paragraph?.children.count, 5)
        XCTAssertNotNil(child0)
        XCTAssertNotNil(child1)
        XCTAssertNotNil(child2)
        XCTAssertNotNil(child3)
        XCTAssertNotNil(child4)
    }
    
    func testAutoLink() throws {
        // given
        let input = "https://example.com"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let text = paragraph?.children[0] as? Text
        let link = paragraph?.children[1] as? Link
        let linkText = link?.children.first as? Text

        // then
        XCTAssertEqual(text?.value, "")
        XCTAssertEqual(link?.url.absoluteString, "https://example.com")
        XCTAssertEqual(link?.title, "")
        XCTAssertEqual(linkText?.value, "https://example.com")
    }

    func testLinkWithEmptyChildTitle() throws {
        // given
        let input = "[](https://example.com)"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children.first as? Link

        // then
        XCTAssertEqual(link?.url.absoluteString, "https://example.com")
        XCTAssertEqual(link?.title, "")
        XCTAssertEqual(link?.children.count, 0)
    }

    func testInternalLink() throws {
        // given
        let input = "[Page 52](#some-topic)"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let link = paragraph?.children.first as? Link
        let linkText = link?.children.first as? Text

        // then
        XCTAssertEqual(link?.url.absoluteString, "#some-topic")
        XCTAssertEqual(link?.title, "")
        XCTAssertEqual(linkText?.value, "Page 52")
    }

    func testImage() throws {
        // given
        let input = #"![alpha](https://example.com/favicon.ico "bravo")"#

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let image = paragraph?.children.first as? Image

        // then
        XCTAssertEqual(image?.url.absoluteString, "https://example.com/favicon.ico")
        XCTAssertEqual(image?.title, "bravo")
        XCTAssertEqual(image?.alt, "alpha")
    }

    func testImageWithLinkInsideAlt() throws {
        // given
        let input = #"![foo [bar](/url)](https://example.com/favicon.ico "bravo")"#

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let image = paragraph?.children.first as? Image
        let link = image?.children[1] as? Link
        let linkText = link?.children.first as? Text

        // then
        XCTAssertEqual(image?.url.absoluteString, "https://example.com/favicon.ico")
        XCTAssertEqual(image?.title, "bravo")
        XCTAssertEqual(image?.alt, "foo bar")
        XCTAssertEqual(link?.url.absoluteString, "/url")
        XCTAssertEqual(linkText?.value, "bar")
    }

    func testStrikethrough() throws {
        // given
        let input = "~~alpha~~"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let delete = paragraph?.children.first as? Delete
        let deleteText = delete?.children.first as? Text

        // then
        XCTAssertEqual(deleteText?.value, "alpha")
    }

    func testStrong() throws {
        // given
        let input = "**alpha**"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Strong
        let text = node?.children.first as? Text

        // then
        XCTAssertEqual(text?.value, "alpha")
    }

    func testStrongUnderscore() throws {
        // given
        let input = "__alpha__"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Strong
        let text = node?.children.first as? Text

        // then
        XCTAssertEqual(text?.value, "alpha")
    }

    func testEmphasis() throws {
        // given
        let input = "*alpha*"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Emphasis
        let text = node?.children.first as? Text

        // then
        XCTAssertEqual(text?.value, "alpha")
    }

    func testEmphasisUnderscore() throws {
        // given
        let input = "_alpha_"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? Emphasis
        let text = node?.children.first as? Text

        // then
        XCTAssertEqual(text?.value, "alpha")
    }

    func testInlineCode() throws {
        // given
        let input = "`alpha`"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children.first as? InlineCode
        let text = node?.value

        // then
        XCTAssertEqual(text, "alpha")
    }

    func testSoftBreak() throws {
        // given
        let input = "foo\nbar"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph

        // then
        XCTAssertNotNil(paragraph?.children[0] as? Text)
        XCTAssertNotNil(paragraph?.children[1] as? SoftBreak)
        XCTAssertNotNil(paragraph?.children[2] as? Text)
    }

    func testLineBreak() throws {
        // given
        let input =
        """
        foo

        baz
        """

        // when
        let tree = try Markdown(text: input).parse()

        // then
        XCTAssertNotNil(tree.children[0] as? Paragraph)
        XCTAssertNotNil(tree.children[1] as? Paragraph)
    }

    func testSpaceLineBreak() throws {
        // given
        let input =
        """
        test  
        test
        """

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph

        // then
        XCTAssertNotNil(paragraph?.children[0] as? Text)
        XCTAssertNotNil(paragraph?.children[1] as? Break)
        XCTAssertNotNil(paragraph?.children[2] as? Text)
    }

    func testFootnoteReference() throws {
        // given
        let input =
        """
        Here is a footnote reference,[^1] and another.[^longnote] and some more [^alpha bravo]

        [^1]: Here is the footnote.
        [^longnote]: Here's one with multiple blocks.
        """

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let node = paragraph?.children[1] as? FootnoteReference
        let node2 = paragraph?.children[3] as? FootnoteReference

        // then
        XCTAssertEqual(node?.identifier, "1")
        XCTAssertEqual(node?.label, "1")
        XCTAssertEqual(node2?.identifier, "2")
        XCTAssertEqual(node2?.label, "2")
    }

    func testHTMLInline() throws {
        // given
        let input = "<del>*foo*</del>"

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children.first as? Paragraph
        let tag1 = paragraph?.children[0] as? HTML
        let emphasis = paragraph?.children[1] as? Emphasis
        let tag2 = paragraph?.children[2] as? HTML

        // then
        XCTAssertEqual(tag1?.value, "<del>")
        XCTAssertEqual((emphasis?.children.first as? Text)?.value, "foo")
        XCTAssertEqual(tag2?.value, "</del>")
    }
}
