import XCTest
@testable import MarkdownSyntax

final class ParserInlineTests: XCTestCase {

    func testLink() throws {
        // given
        let input = #"[alpha](https://example.com "bravo")"#

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let link = paragraph.children.first as! Link
        let linkText = link.children.first as! Text

        // then
        XCTAssertEqual(link.type, .link)
        XCTAssertEqual(link.url.absoluteString, "https://example.com")
        XCTAssertEqual(link.title, "bravo")
        XCTAssertEqual(linkText.value, "alpha")
    }
    
    func testAutoLink() throws {
        // given
        let input = "https://example.com"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let text = paragraph.children[0] as! Text
        let link = paragraph.children[1] as! Link
        let linkText = link.children.first as! Text

        // then
        XCTAssertEqual(text.value, "")
        XCTAssertEqual(link.type, .link)
        XCTAssertEqual(link.url.absoluteString, "https://example.com")
        XCTAssertEqual(link.title, "")
        XCTAssertEqual(linkText.value, "https://example.com")
    }

    func testLinkWithEmptyChildTitle() throws {
        // given
        let input = "[](https://example.com)"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let link = paragraph.children.first as! Link

        // then
        XCTAssertEqual(link.type, .link)
        XCTAssertEqual(link.url.absoluteString, "https://example.com")
        XCTAssertEqual(link.title, "")
        XCTAssertEqual(link.children.count, 0)
    }

    func testInternalLink() throws {
        // given
        let input = "[Page 52](#some-topic)"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let link = paragraph.children.first as! Link
        let linkText = link.children.first as! Text

        // then
        XCTAssertEqual(link.type, .link)
        XCTAssertEqual(link.url.absoluteString, "#some-topic")
        XCTAssertEqual(link.title, "")
        XCTAssertEqual(linkText.value, "Page 52")
    }

    func testImage() throws {
        // given
        let input = #"![alpha](https://example.com/favicon.ico "bravo")"#

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let image = paragraph.children.first as! Image

        // then
        XCTAssertEqual(image.type, .image)
        XCTAssertEqual(image.url.absoluteString, "https://example.com/favicon.ico")
        XCTAssertEqual(image.title, "bravo")
        XCTAssertEqual(image.alt, "alpha")
    }

    func testImageWithLinkInsideAlt() throws {
        // given
        let input = #"![foo [bar](/url)](https://example.com/favicon.ico "bravo")"#

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let image = paragraph.children.first as! Image
        let link = image.children[1] as! Link
        let linkText = link.children.first as! Text

        // then
        XCTAssertEqual(image.type, .image)
        XCTAssertEqual(image.url.absoluteString, "https://example.com/favicon.ico")
        XCTAssertEqual(image.title, "bravo")
        XCTAssertEqual(image.alt, "foo bar")
        XCTAssertEqual(link.url.absoluteString, "/url")
        XCTAssertEqual(linkText.value, "bar")
    }

    func testStrikethrough() throws {
        // given
        let input = "~~alpha~~"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let delete = paragraph.children.first as! Delete
        let deleteText = delete.children.first as! Text

        // then
        XCTAssertEqual(delete.type, .delete)
        XCTAssertEqual(deleteText.value, "alpha")
    }

    func testStrong() throws {
        // given
        let input = "**alpha**"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let node = paragraph.children.first as! Strong
        let text = node.children.first as! Text

        // then
        XCTAssertEqual(node.type, .strong)
        XCTAssertEqual(text.value, "alpha")
    }

    func testStrongUnderscore() throws {
        // given
        let input = "__alpha__"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let node = paragraph.children.first as! Strong
        let text = node.children.first as! Text

        // then
        XCTAssertEqual(node.type, .strong)
        XCTAssertEqual(text.value, "alpha")
    }

    func testEmphasis() throws {
        // given
        let input = "*alpha*"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let node = paragraph.children.first as! Emphasis
        let text = node.children.first as! Text

        // then
        XCTAssertEqual(node.type, .emphasis)
        XCTAssertEqual(text.value, "alpha")
    }

    func testEmphasisUnderscore() throws {
        // given
        let input = "_alpha_"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let node = paragraph.children.first as! Emphasis
        let text = node.children.first as! Text

        // then
        XCTAssertEqual(node.type, .emphasis)
        XCTAssertEqual(text.value, "alpha")
    }

    func testInlineCode() throws {
        // given
        let input = "`alpha`"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let node = paragraph.children.first as! InlineCode
        let text = node.value

        // then
        XCTAssertEqual(node.type, .inlineCode)
        XCTAssertEqual(text, "alpha")
    }

    func testBreak() throws {
        // given
        let input = "foo\rbar"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph

        // then
        XCTAssertNotNil(paragraph.children[0] as? Text)
        XCTAssertNotNil(paragraph.children[1] as? Break)
        XCTAssertNotNil(paragraph.children[2] as? Text)
    }

    func testLineBreak() throws {
        // given
        let input =
        """
        foo

        baz
        """

        // when
        let tree = try Parser().parse(text: input)

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
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph

        // then
        XCTAssertNotNil(paragraph.children[0] as? Text)
        XCTAssertNotNil(paragraph.children[1] as? LineBreak)
        XCTAssertNotNil(paragraph.children[2] as? Text)
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
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph
        let node = paragraph.children[1] as! FootnoteReference
        let node2 = paragraph.children[3] as! FootnoteReference

        // then
        XCTAssertEqual(node.type, .footnoteReference)
        XCTAssertEqual(node2.type, .footnoteReference)
        XCTAssertEqual(node.identifier, "1")
        XCTAssertEqual(node.label, "1")
        XCTAssertEqual(node2.identifier, "2")
        XCTAssertEqual(node2.label, "2")
    }
}
