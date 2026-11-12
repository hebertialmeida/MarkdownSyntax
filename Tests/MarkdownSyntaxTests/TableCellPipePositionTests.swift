//
//  TableCellPipePositionTests.swift
//  MarkdownSyntaxTests
//
//  A GFM table reads `\|` in a cell as `|` before it parses the cell's inlines, and cmark places
//  them in that shorter text: each `\|` before a node used to move its range one byte early, so a
//  text holding one ended a byte short. Positions now come from the source as written.
//

import Foundation
import XCTest
@testable import MarkdownSyntax

final class TableCellPipePositionTests: XCTestCase {

    /// The source each node of the cells covers, by kind, in tree order.
    private func cellNodes(_ text: String) async throws -> [(kind: String, source: String)] {
        let markdown = try await Markdown(text: text)
        let tree = await markdown.parse()
        var found: [(String, String)] = []
        func visit(_ nodes: [Node], inCell: Bool) {
            for node in nodes {
                if inCell, let range = node.position.range {
                    found.append(("\(type(of: node))", String(text[range])))
                }
                let isCell = node is TableCell
                if let parent = node as? any Parent {
                    visit(Self.children(of: parent), inCell: inCell || isCell)
                }
            }
        }
        visit(tree.children, inCell: false)
        return found
    }

    private static func children<P: Parent>(of parent: P) -> [Node] {
        parent.children.compactMap { $0 as? Node }
    }

    func testATextHoldingAnEscapedPipeCoversItWhole() async throws {
        let nodes = try await cellNodes("| a | b |\n|---|---|\n| [[C\\|D]] | x |")
        XCTAssertEqual(nodes.map(\.source), ["a", "b", "[[C\\|D]]", "x"])
    }

    func testTextAfterAnEscapedPipeStartsWhereItIsWritten() async throws {
        let nodes = try await cellNodes("| a |\n|---|\n| x \\| *em* \\| `c` y |")
        XCTAssertEqual(nodes.map(\.kind), ["Text", "Text", "Emphasis", "Text", "Text", "InlineCode", "Text"])
        XCTAssertEqual(nodes.map(\.source), ["a", "x \\| ", "*em*", "em", " \\| ", "`c`", " y"])
    }

    func testSeveralEscapedPipesInSeveralCells() async throws {
        let nodes = try await cellNodes("| h1 | h2 |\n|---|---|\n| a \\| b \\| c | [[A\\|B]] and [[C\\|D]] |\n")
        XCTAssertEqual(nodes.map(\.source), ["h1", "h2", "a \\| b \\| c", "[[A\\|B]] and [[C\\|D]]"])
    }

    func testCellsWithMultibyteTextAndEscapedPipes() async throws {
        let nodes = try await cellNodes("| é |\n|---|\n| ☃ \\| é **ü** |")
        XCTAssertEqual(nodes.map(\.source), ["é", "☃ \\| é ", "**ü**", "ü"])
    }

    func testCellsWithoutEscapedPipesKeepTheirRanges() async throws {
        let nodes = try await cellNodes("| a | *b* |\n|---|---|\n| [[C]] | `x` |")
        XCTAssertEqual(nodes.map(\.source), ["a", "*b*", "b", "[[C]]", "`x`"])
    }

    func testRenderingPartOfACellWithAnEscapedPipeFindsItsNodes() async throws {
        let markdown = try await Markdown(text: "| a |\n|---|\n| x \\| *em* |")
        let tree = await markdown.parse()
        let table = try XCTUnwrap(tree.children.first as? Table)
        let cell = try XCTUnwrap((table.children.last as? TableRow)?.children.first as? TableCell)
        let emphasis = try XCTUnwrap(cell.children.last as? Emphasis)
        let html = try await markdown.renderHtml(of: [emphasis])
        XCTAssertEqual(html, "<em>em</em>")
    }
}
