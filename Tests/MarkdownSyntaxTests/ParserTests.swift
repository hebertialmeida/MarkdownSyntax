import XCTest
@testable import MarkdownSyntax

final class ParserTests: XCTestCase {

    func testLineOffsets() async throws {
        // given
        let input = "Line 1\nLine 2\rLine 3\r\nLine 4"

        // when
        let tree = try await Markdown(text: input).parse()

        // then
        XCTAssertEqual(input.lineOffsets.count, 4)
        XCTAssertEqual((tree.children.first as? Paragraph)?.children.count, 7)
    }
}
