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
        let tree = try Parser().parse(text: input)
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
        """

        // when
        let tree = try Parser().parse(text: input)
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
}
