import XCTest
@testable import MarkdownSyntax

final class ParserTests: XCTestCase {

    func testLineOffsets() throws {
        // given
        let input = "Line 1\nLine 2\rLine 3\r\nLine 4"

        // then
        XCTAssertEqual(input.lineOffsets.count, 4)
    }
}
