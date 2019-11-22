import XCTest
@testable import MarkdownSyntax

final class ContentBlockPositionTests: XCTestCase {

    func testHeadingWithInline() throws {
        // given
        let input =
        """
        # Header 👨‍👩‍👦‍👦 with **bold** text

        This book **focuses on *five different* implementations** of the Recordings **application** using the following application design *patterns*.
        """

        // when
        let tree = try Markdown(text: input).parse()
        let heading1 = tree.children[0] as? Heading
        let headingStrong = heading1?.children[1] as? Strong

        let headingRange = input.range(0...28)
        let headingStrongRange = input.range(16...23)

        // then
        XCTAssertEqual(heading1?.position.range, headingRange)
        XCTAssertEqual(input[headingRange], "# Header 👨‍👩‍👦‍👦 with **bold** text")
        XCTAssertEqual(headingStrong?.position.range, headingStrongRange)
        XCTAssertEqual(input[headingStrongRange], "**bold**")
    }

    func testParagraphWithInline() throws {
        // given
        let input =
        """
        # Header 👨‍👩‍👦‍👦 with **bold** text

        This book **focuses on *five different* implementations** of the Recordings **application** using the following application design *patterns*.

        Now adding some `alpha-inline` code.
        """

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children[1] as? Paragraph
        let paragraphStrong = paragraph?.children[1] as? Strong
        let paragraphEmphasis = paragraphStrong?.children[1] as? Emphasis
        let paragraphStrong2 = paragraph?.children[3] as? Strong

        let paragraphRange = input.range(31...172)
        let paragraphStrongRange = input.range(41...87)
        let paragraphEmphasisRange = input.range(54...69)
        let paragraphStrongRange2 = input.range(107...121)

        // then
        XCTAssertEqual(paragraph?.position.range, paragraphRange)
        XCTAssertEqual(input[paragraphRange], "This book **focuses on *five different* implementations** of the Recordings **application** using the following application design *patterns*.")

        XCTAssertEqual(paragraphStrong?.position.range, paragraphStrongRange)
        XCTAssertEqual(input[paragraphStrongRange], "**focuses on *five different* implementations**")

        XCTAssertEqual(paragraphEmphasis?.position.range, paragraphEmphasisRange)
        XCTAssertEqual(input[paragraphEmphasisRange], "*five different*")

        XCTAssertEqual(paragraphStrong2?.position.range, paragraphStrongRange2)
        XCTAssertEqual(input[paragraphStrongRange2], "**application**")
    }

    func testParagraphWithInlineCode() throws {
        // given
        let input =
        """
        # Header 👨‍👩‍👦‍👦 with **bold** text

        This book **focuses on *five different* implementations** of the Recordings **application** using the following application design *patterns*.

        Now adding some `alpha-inline` code.
        """

        // when
        let tree = try Markdown(text: input).parse()
        let paragraph = tree.children[2] as? Paragraph
        let inlineCode = paragraph?.children[1] as? InlineCode

        let inlineCodeRange = input.range(191...204)

        // then
        XCTAssertEqual(inlineCode?.position.range, inlineCodeRange)
        XCTAssertEqual(input[inlineCodeRange], "`alpha-inline`")
    }

    func testBlockquotePosition() throws {
        // given
        let input =
        """
        > Alpha bravo charlie.
        > This is the second line.
        """

        // when
        let tree = try Markdown(text: input).parse()
        let blockquote = tree.children.first as? Blockquote
        let paragraph = blockquote?.children.first as? Paragraph
        let text = paragraph?.children.first as? Text
        let softBreak = paragraph?.children[1] as? SoftBreak
        let text2 = paragraph?.children[2] as? Text

        let textRange = input.range(2...21)
        let textRange2 = input.range(25...48)

        // then
        XCTAssertEqual(blockquote?.type, .blockquote)
        XCTAssertEqual(softBreak?.type, .softBreak)
        XCTAssertEqual(text?.position.range, textRange)
        XCTAssertEqual(text2?.position.range, textRange2)
    }

    func testFootnoteDefinitionPosition() throws {
        // given
        let input =
        """
        Here is a footnote reference,[^1] and another.[^longnote] and some more [^alpha bravo]

        [^1]: Here is the footnote.
        [^longnote]: Here's one with multiple blocks.
        """

        // when
        let tree = try Markdown(text: input).parse()
        let node = tree.children[1] as? FootnoteDefinition
        let node2 = tree.children[2] as? FootnoteDefinition
        let range = input.range(88...92)
        let range2 = input.range(116...127)

        // then
//        XCTAssertEqual(node?.position.range, range)
        XCTAssertEqual(input[node!.position.range!], "[^1]: Here is the footnote.")
        XCTAssertEqual(input[range], "[^1]:")
//        XCTAssertEqual(node2?.position.range, range2)
        XCTAssertEqual(input[node2!.position.range!], "[^longnote]: Here's one with multiple blocks.")
        XCTAssertEqual(input[range2], "[^longnote]:")
    }

    func testHTMLPosition() throws {
        // given
        let input = "<div>this</div>"

        // when
        let tree = try Markdown(text: input).parse()
        let node = tree.children.first as? HTML
        let range = input.range(0...15)

        // then
        XCTAssertEqual(input[node!.position.range!], "<div>this</div>")
        XCTAssertEqual(input[range], "<div>this</div>")
    }

    // Because html comment is a inline element seems that the behaviour is weird, double check this later
    func testHTMLCommentPosition() throws {
        // given
        let input = "<!-- this -->\n"

        // when
        let tree = try Markdown(text: input).parse()
        let node = tree.children.first as? HTML
        let range = input.range(0...13)

        // then
        XCTAssertEqual(input[node!.position.range!], "<!-- this -->")
        XCTAssertEqual(input[range], "<!-- this -->\n")
    }
}
