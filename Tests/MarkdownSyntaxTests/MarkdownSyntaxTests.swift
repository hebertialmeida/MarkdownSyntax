import XCTest
@testable import MarkdownSyntax

final class MarkdownSyntaxTests: XCTestCase {

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

    func testBreak() throws {
        // given
        let input = "foo\rbar"

        // when
        let tree = try Parser().parse(text: input)
        let paragraph = tree.children.first as! Paragraph

//        // then
        XCTAssertNotNil(paragraph.children[0] as? Text)
        XCTAssertNotNil(paragraph.children[1] as? Break)
        XCTAssertNotNil(paragraph.children[2] as? Text)
    }

//    func testFootnote() throws {
//        FootnoteDefinition "[^alpha]: bravo and charlie."
//        Footnote "[^alpha bravo]"
//        FootnoteReference "[^alpha]"
//    }
}
