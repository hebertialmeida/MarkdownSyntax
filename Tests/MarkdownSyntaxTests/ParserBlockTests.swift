import XCTest
@testable import MarkdownSyntax

final class ParserBlockTests: XCTestCase {

    func testHeading() async throws {
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
        let tree = try await Markdown(text: input).parse()
        let heading1 = tree.children[0] as? Heading
        let text1 = heading1?.children.first as? Text
        let heading2 = tree.children[1] as? Heading
        let text2 = heading2?.children.first as? Text
        let heading3 = tree.children[2] as? Heading
        let text3 = heading3?.children.first as? Text
        let heading4 = tree.children[3] as? Heading
        let text4 = heading4?.children.first as? Text
        let heading5 = tree.children[4] as? Heading
        let text5 = heading5?.children.first as? Text
        let heading6 = tree.children[5] as? Heading
        let text6 = heading6?.children.first as? Text

        // then
        XCTAssertEqual(text1?.value, "Header 1")
        XCTAssertEqual(text2?.value, "Header 2")
        XCTAssertEqual(text3?.value, "Header 3")
        XCTAssertEqual(text4?.value, "Header 4")
        XCTAssertEqual(text5?.value, "Header 5")
        XCTAssertEqual(text6?.value, "Header 6")
    }

    func testFootnoteDefinition() async throws {
        // given
        let input =
        """
        Here is a footnote reference,[^1] and another.[^longnote] and some more [^alpha bravo]

        [^1]: Here is the footnote.
        [^longnote]: Here's one with multiple blocks.
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let definition = tree.children[1] as? FootnoteDefinition
        let paragraph = definition?.children.first as? Paragraph
        let text = paragraph?.children.first as? Text

        let definition2 = tree.children[2] as? FootnoteDefinition
        let paragraph2 = definition2?.children.first as? Paragraph
        let text2 = paragraph2?.children.first as? Text

        // then
        XCTAssertEqual(definition?.identifier, "1")
        XCTAssertEqual(definition2?.identifier, "2")
        XCTAssertEqual(text?.value, "Here is the footnote.")
        XCTAssertEqual(text2?.value, "Here's one with multiple blocks.")
    }

    func testBlockquote() async throws {
        // given
        let input =
        """
        > Alpha bravo charlie.
        > This is the second line.
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let blockquote = tree.children.first as? Blockquote
        let paragraph = blockquote?.children.first as? Paragraph
        let text = paragraph?.children.first as? Text
        let softBreak = paragraph?.children[1] as? SoftBreak
        let text2 = paragraph?.children[2] as? Text

        // then
        XCTAssertNotNil(softBreak)
        XCTAssertEqual(text?.value, "Alpha bravo charlie.")
        XCTAssertEqual(text2?.value, "This is the second line.")
    }

    func testThematicBreak() async throws {
        // given
        let input =
        """
        Alpha bravo charlie.
        * * *
        This is the second line.
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let thematicBreak = tree.children[1] as? ThematicBreak

        // then
        XCTAssertNotNil(thematicBreak)
    }

    func testCode() async throws {
        // given
        let input =
        """
        ```swift
        func some() {
            print("code")
        }
        ```
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let code = tree.children.first as? Code

        // then
        XCTAssertEqual(code?.language, "swift")
        XCTAssertEqual(code?.meta, nil)
        XCTAssertEqual(code?.value, "func some() {\n    print(\"code\")\n}\n")
    }

    func testHTML() async throws {
        // given
        let input =
        """
        <div id="foo"
          class="bar">
        </div>
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let code = tree.children.first as? HTML

        // then
        XCTAssertEqual(code?.value, "<div id=\"foo\"\n  class=\"bar\">\n</div>\n")
    }

    func testHTMLComment() async throws {
        // given
        let input = "<!-- this -->\n"

        // when
        let tree = try await Markdown(text: input).parse()
        let code = tree.children.first as? HTML

        // then
        XCTAssertEqual(code?.value, "<!-- this -->\n")
    }

    // MARK: - List

    func testList() async throws {
        // given
        let input =
        """
        - First
        - Second
        - Third
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let list = tree.children.first as? List
        let first = list?.children[0] as? ListItem
        let second = list?.children[1] as? ListItem
        let third = list?.children[2] as? ListItem
        let text = (first?.children.first as? Paragraph)?.children.first as? Text
        let text2 = (second?.children.first as? Paragraph)?.children.first as? Text
        let text3 = (third?.children.first as? Paragraph)?.children.first as? Text

        // then
        XCTAssertEqual(list?.ordered, false)
        XCTAssertEqual(list?.start, nil)
        XCTAssertEqual(list?.spread, false)

        XCTAssertEqual(first?.checked, nil)
        XCTAssertEqual(first?.spread, false)
        XCTAssertEqual(text?.value, "First")

        XCTAssertEqual(second?.checked, nil)
        XCTAssertEqual(second?.spread, false)
        XCTAssertEqual(text2?.value, "Second")

        XCTAssertEqual(third?.checked, nil)
        XCTAssertEqual(third?.spread, false)
        XCTAssertEqual(text3?.value, "Third")
    }

    func testListOrdered() async throws {
        // given
        let input =
        """
        1. First
        2. Second
        3. Third
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let list = tree.children.first as? List
        let first = list?.children[0] as? ListItem
        let second = list?.children[1] as? ListItem
        let third = list?.children[2] as? ListItem
        let text = (first?.children.first as? Paragraph)?.children.first as? Text
        let text2 = (second?.children.first as? Paragraph)?.children.first as? Text
        let text3 = (third?.children.first as? Paragraph)?.children.first as? Text

        // then
        XCTAssertEqual(list?.ordered, true)
        XCTAssertEqual(list?.start, 1)
        XCTAssertEqual(list?.spread, false)

        XCTAssertEqual(first?.checked, nil)
        XCTAssertEqual(first?.spread, false)
        XCTAssertEqual(text?.value, "First")

        XCTAssertEqual(second?.checked, nil)
        XCTAssertEqual(second?.spread, false)
        XCTAssertEqual(text2?.value, "Second")

        XCTAssertEqual(third?.checked, nil)
        XCTAssertEqual(third?.spread, false)
        XCTAssertEqual(text3?.value, "Third")
    }

    func testListTask() async throws {
        // given
        let input =
        """
        - [ ] First
        - [x] Second
        - [X] Third
        - [] Fourth
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let list = tree.children.first as? List
        let first = list?.children[0] as? ListItem
        let second = list?.children[1] as? ListItem
        let third = list?.children[2] as? ListItem
        let fourth = list?.children[3] as? ListItem
        let text = (first?.children.first as? Paragraph)?.children.first as? Text
        let text2 = (second?.children.first as? Paragraph)?.children.first as? Text
        let text3 = (third?.children.first as? Paragraph)?.children.first as? Text
        let text4 = (fourth?.children.first as? Paragraph)?.children.first as? Text

        // then
        XCTAssertEqual(list?.ordered, false)
        XCTAssertEqual(list?.start, nil)
        XCTAssertEqual(list?.spread, false)

        XCTAssertEqual(first?.checked, false)
        XCTAssertEqual(first?.spread, false)
        XCTAssertEqual(text?.value, "First")

        XCTAssertEqual(second?.checked, true)
        XCTAssertEqual(second?.spread, false)
        XCTAssertEqual(text2?.value, "Second")

        XCTAssertEqual(third?.checked, true)
        XCTAssertEqual(third?.spread, false)
        XCTAssertEqual(text3?.value, "Third")

        XCTAssertEqual(fourth?.checked, nil)
        XCTAssertEqual(fourth?.spread, false)
        XCTAssertEqual(text4?.value, "[] Fourth")
    }

    func testListSpread() async throws {
        // given
        let input =
        """
        - First

        - Second

        - Third
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let list = tree.children.first as? List
        let first = list?.children[0] as? ListItem
        let second = list?.children[1] as? ListItem
        let third = list?.children[2] as? ListItem
        let text = (first?.children.first as? Paragraph)?.children.first as? Text
        let text2 = (second?.children.first as? Paragraph)?.children.first as? Text
        let text3 = (third?.children.first as? Paragraph)?.children.first as? Text

        // then
        XCTAssertEqual(list?.spread, true)

        XCTAssertEqual(first?.checked, nil)
        XCTAssertEqual(first?.spread, true)
        XCTAssertEqual(text?.value, "First")

        XCTAssertEqual(second?.checked, nil)
        XCTAssertEqual(second?.spread, true)
        XCTAssertEqual(text2?.value, "Second")

        XCTAssertEqual(third?.checked, nil)
        XCTAssertEqual(third?.spread, true)
        XCTAssertEqual(text3?.value, "Third")
    }

    func testListHierarchy() async throws {
        // given
        let input =
        """
        - First
            - Second
                - Third
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let list = tree.children.first as? List
        let first = list?.children[0] as? ListItem
        let second = (first?.children[1] as? List)?.children.first as? ListItem
        let third = (second?.children[1] as? List)?.children.first as? ListItem
        let text = (first?.children.first as? Paragraph)?.children.first as? Text
        let text2 = (second?.children.first as? Paragraph)?.children.first as? Text
        let text3 = (third?.children.first as? Paragraph)?.children.first as? Text

        // then
        XCTAssertEqual(list?.spread, false)

        XCTAssertEqual(first?.checked, nil)
        XCTAssertEqual(first?.spread, false)
        XCTAssertEqual(text?.value, "First")

        XCTAssertEqual(second?.checked, nil)
        XCTAssertEqual(second?.spread, false)
        XCTAssertEqual(text2?.value, "Second")

        XCTAssertEqual(third?.checked, nil)
        XCTAssertEqual(third?.spread, false)
        XCTAssertEqual(text3?.value, "Third")
    }

    func testListHierarchySpread() async throws {
        // given
        let input =
        """
        - First

            - Second

                - Third

                - Third 2
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let list = tree.children.first as? List
        let first = list?.children[0] as? ListItem
        let second = (first?.children[1] as? List)?.children.first as? ListItem
        let third = (second?.children[1] as? List)?.children.first as? ListItem
        let text = (first?.children.first as? Paragraph)?.children.first as? Text
        let text2 = (second?.children.first as? Paragraph)?.children.first as? Text
        let text3 = (third?.children.first as? Paragraph)?.children.first as? Text

        // then
        XCTAssertEqual(list?.spread, true)

        XCTAssertEqual(first?.checked, nil)
        XCTAssertEqual(first?.spread, true)
        XCTAssertEqual(text?.value, "First")

        XCTAssertEqual(second?.checked, nil)
        XCTAssertEqual(second?.spread, true)
        XCTAssertEqual(text2?.value, "Second")

        XCTAssertEqual(third?.checked, nil)
        XCTAssertEqual(third?.spread, true)
        XCTAssertEqual(text3?.value, "Third")
    }

    // MARK: - Table

    func testTable() async throws {
        // given
        let input =
        """
        | foo | bar | mar | tara |
        | :-- | :-: | --- | ---: |
        | baz | qux | zee | zeet |
        """

        // when
        let tree = try await Markdown(text: input).parse()
        let table = tree.children.first as? Table
        let row0 = table?.children[0] as? TableRow
        let row1 = table?.children[1] as? TableRow

        let textCell0Row0 = (row0?.children[0] as? TableCell)?.children[0] as? Text
        let textCell1Row0 = (row0?.children[1] as? TableCell)?.children[0] as? Text
        let textCell2Row0 = (row0?.children[2] as? TableCell)?.children[0] as? Text
        let textCell3Row0 = (row0?.children[3] as? TableCell)?.children[0] as? Text

        let textCell0Row1 = (row1?.children[0] as? TableCell)?.children[0] as? Text
        let textCell1Row1 = (row1?.children[1] as? TableCell)?.children[0] as? Text
        let textCell2Row1 = (row1?.children[2] as? TableCell)?.children[0] as? Text
        let textCell3Row1 = (row1?.children[3] as? TableCell)?.children[0] as? Text

        // then
        XCTAssertEqual(table?.align, [.left, .center, .none, .right])

        XCTAssertEqual(row0?.isHeader, true)
        XCTAssertEqual(row1?.isHeader, false)

        XCTAssertEqual(textCell0Row0?.value, "foo")
        XCTAssertEqual(textCell1Row0?.value, "bar")
        XCTAssertEqual(textCell2Row0?.value, "mar")
        XCTAssertEqual(textCell3Row0?.value, "tara")

        XCTAssertEqual(textCell0Row1?.value, "baz")
        XCTAssertEqual(textCell1Row1?.value, "qux")
        XCTAssertEqual(textCell2Row1?.value, "zee")
        XCTAssertEqual(textCell3Row1?.value, "zeet")
    }
}
