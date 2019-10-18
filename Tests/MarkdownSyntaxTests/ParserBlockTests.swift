import XCTest
@testable import MarkdownSyntax

final class ParserBlockTests: XCTestCase {

    func testHeading() throws {
        // given
        let input =
        """
        # Header 1
        ## Header 2
        ### Header 3
        #### Header 4
        ##### Header 5
        ###### Header 6
        """

        // when
        let tree = try Parser().parse(text: input)
        let heading1 = tree.children[0] as! Heading
        let text1 = heading1.children.first as! Text
        let heading2 = tree.children[1] as! Heading
        let text2 = heading2.children.first as! Text
        let heading3 = tree.children[2] as! Heading
        let text3 = heading3.children.first as! Text
        let heading4 = tree.children[3] as! Heading
        let text4 = heading4.children.first as! Text
        let heading5 = tree.children[4] as! Heading
        let text5 = heading5.children.first as! Text
        let heading6 = tree.children[5] as! Heading
        let text6 = heading6.children.first as! Text

        // then
        XCTAssertEqual(heading1.type, .heading)
        XCTAssertEqual(heading2.type, .heading)
        XCTAssertEqual(heading3.type, .heading)
        XCTAssertEqual(heading4.type, .heading)
        XCTAssertEqual(heading5.type, .heading)
        XCTAssertEqual(heading6.type, .heading)

        XCTAssertEqual(text1.value, "Header 1")
        XCTAssertEqual(text2.value, "Header 2")
        XCTAssertEqual(text3.value, "Header 3")
        XCTAssertEqual(text4.value, "Header 4")
        XCTAssertEqual(text5.value, "Header 5")
        XCTAssertEqual(text6.value, "Header 6")
    }

    func testFootnoteDefinition() throws {
        // given
        let input =
        """
        Here is a footnote reference,[^1] and another.[^longnote] and some more [^alpha bravo]

        [^1]: Here is the footnote.
        [^longnote]: Here's one with multiple blocks.
        """

        // when
        let tree = try Parser().parse(text: input)
        let definition = tree.children[1] as! FootnoteDefinition
        let paragraph = definition.children.first as! Paragraph
        let text = paragraph.children.first as! Text

        let definition2 = tree.children[2] as! FootnoteDefinition
        let paragraph2 = definition2.children.first as! Paragraph
        let text2 = paragraph2.children.first as! Text

        // then
        XCTAssertEqual(definition.type, .footnoteDefinition)
        XCTAssertEqual(definition2.type, .footnoteDefinition)
        XCTAssertEqual(definition.identifier, "1")
        XCTAssertEqual(definition2.identifier, "2")
        XCTAssertEqual(text.value, "Here is the footnote.")
        XCTAssertEqual(text2.value, "Here's one with multiple blocks.")
    }

    func testBlockquote() throws {
        // given
        let input =
        """
        > Alpha bravo charlie.
        > This is the second line.
        """

        // when
        let tree = try Parser().parse(text: input)
        let blockquote = tree.children.first as! Blockquote
        let paragraph = blockquote.children.first as! Paragraph
        let text = paragraph.children.first as! Text
        let softBreak = paragraph.children[1] as! Break
        let text2 = paragraph.children[2] as! Text

        // then
        XCTAssertEqual(blockquote.type, .blockquote)
        XCTAssertEqual(softBreak.type, .break)
        XCTAssertEqual(text.value, "Alpha bravo charlie.")
        XCTAssertEqual(text2.value, "This is the second line.")
    }
}
