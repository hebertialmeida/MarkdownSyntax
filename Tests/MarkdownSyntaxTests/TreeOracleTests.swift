//
//  TreeOracleTests.swift
//  MarkdownSyntaxTests
//
//  The tree oracle: the whole tree `parse()` returns for the generated fixtures, every node's
//  type, fields, line:column and UTF-8 offsets, compared with a dump recorded from 1.4.1.
//  Speed work must leave this byte-identical.
//
//  The fixtures are written by `swift run -c release Benchmarks --write-fixtures
//  Tests/MarkdownSyntaxTests/Fixtures`. Each is checked with `\n`, `\r\n`, lone `\r` and mixed
//  line endings. The 4 kB dumps are kept in full; the larger ones as a digest in
//  `oracle-digests.txt`. A mismatch writes this run's dump to the temporary directory; record
//  the expected one from the earlier version to `diff` them. To re-record (only for an intended
//  change of the tree), run the suite with `MARKDOWNSYNTAX_RECORD_ORACLE=1`.
//

import Foundation
import XCTest
@testable import MarkdownSyntax

final class TreeOracleTests: XCTestCase {

    /// Recorded in full, so a difference can be read with `diff`.
    private static let dumped = ["generated-4k"]
    /// Recorded as a digest of the dump: the full dumps are megabytes.
    private static let digested = ["generated-64k", "generated-128k"]
    private static let digestsFile = "oracle-digests.txt"

    func testTreeMatchesRecordedOracleForEveryFixtureAndLineEnding() async throws {
        let record = ProcessInfo.processInfo.environment["MARKDOWNSYNTAX_RECORD_ORACLE"] == "1"
        let directory = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        let digests = record ? [:] : try Self.readDigests(at: directory.appendingPathComponent(Self.digestsFile))
        var recordedDigests: [String] = []

        for name in Self.dumped + Self.digested {
            let source = try String(contentsOf: directory.appendingPathComponent("\(name).md"), encoding: .utf8)
            for ending in LineEnding.allCases {
                let text = ending.apply(to: source)
                let dump = TreeDump.dump(try await Markdown(text: text).parse(), in: text)
                let file = "\(name).\(ending.rawValue).tree"
                let isDumped = Self.dumped.contains(name)

                if record {
                    if isDumped {
                        try dump.write(to: sourceDirectory.appendingPathComponent(file), atomically: true, encoding: .utf8)
                    } else {
                        recordedDigests.append("\(file) \(TreeDump.digest(dump))")
                    }
                    continue
                }

                let matches = isDumped
                    ? dump == (try String(contentsOf: directory.appendingPathComponent(file), encoding: .utf8))
                    : TreeDump.digest(dump) == digests[file]
                if !matches {
                    let actual = FileManager.default.temporaryDirectory.appendingPathComponent(file)
                    try dump.write(to: actual, atomically: true, encoding: .utf8)
                    XCTFail("\(file) differs from the recorded tree; this run's dump is at \(actual.path)")
                }
            }
        }

        if record {
            let contents = recordedDigests.joined(separator: "\n") + "\n"
            try contents.write(to: sourceDirectory.appendingPathComponent(Self.digestsFile), atomically: true, encoding: .utf8)
        }
    }

    /// Short documents that each end in a different block or inline, with no newline after the
    /// last line: the last node's end is then the end of the text, not a line break.
    private static let noFinalNewline: [(name: String, text: String)] = [
        ("paragraph-multibyte", "Intro.\n\nCafé 🇧🇷 *fin*"),
        ("heading-atx", "Text.\n\n## Título"),
        ("heading-setext", "Título\n======"),
        ("list-item", "- one\n- two **é**"),
        ("ordered-nested", "1. one\n   - inner `code`"),
        ("quote-nested", "> outer\n> > [!note] inner é"),
        ("quote-in-list", "- item\n\n  > quoted"),
        ("table", "| a | b |\n| - | - |\n| é | 2 |"),
        ("fence-closed", "```swift\nlet x = 1\n```"),
        ("fence-unclosed", "```\nlet x = 1"),
        ("indented-code", "Text.\n\n    code line"),
        ("html-block", "<div>\nhtml é\n</div>"),
        ("thematic-break", "Text.\n\n---"),
        ("footnote-definition", "Text[^1].\n\n[^1]: The note é"),
        ("hard-break", "line one\\\nline two"),
        ("link-and-image", "[link](https://example.com) ![alt](a.png)"),
        ("trailing-spaces", "Text.   "),
    ]
    private static let noFinalNewlineFile = "no-final-newline.tree"

    /// The fixtures again with their trailing newlines removed, and the short documents above:
    /// the last line of each has no line break, in every line ending.
    func testTreeMatchesRecordedOracleWhenTheLastLineHasNoNewline() async throws {
        let record = ProcessInfo.processInfo.environment["MARKDOWNSYNTAX_RECORD_ORACLE"] == "1"
        let directory = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures", withExtension: nil))
        let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        let digestsURL = (record ? sourceDirectory : directory).appendingPathComponent(Self.digestsFile)
        let digests = record ? [:] : try Self.readDigests(at: digestsURL)
        var recordedDigests: [String] = []

        for name in Self.dumped + Self.digested {
            var source = try String(contentsOf: directory.appendingPathComponent("\(name).md"), encoding: .utf8)
            while source.hasSuffix("\n") { source.removeLast() }
            for ending in LineEnding.allCases {
                let text = ending.apply(to: source)
                let dump = TreeDump.dump(try await Markdown(text: text).parse(), in: text)
                let file = "\(name).\(ending.rawValue).no-final-newline.tree"
                if record {
                    recordedDigests.append("\(file) \(TreeDump.digest(dump))")
                } else if TreeDump.digest(dump) != digests[file] {
                    let actual = FileManager.default.temporaryDirectory.appendingPathComponent(file)
                    try dump.write(to: actual, atomically: true, encoding: .utf8)
                    XCTFail("\(file) differs from the recorded tree; this run's dump is at \(actual.path)")
                }
            }
        }

        var dumps = ""
        for (name, source) in Self.noFinalNewline {
            for ending in LineEnding.allCases {
                let text = ending.apply(to: source)
                dumps += "## \(name).\(ending.rawValue)\n"
                dumps += TreeDump.dump(try await Markdown(text: text).parse(), in: text)
            }
        }

        if record {
            try dumps.write(to: sourceDirectory.appendingPathComponent(Self.noFinalNewlineFile), atomically: true, encoding: .utf8)
            // The other test's digests stay first, in their order.
            let kept = try String(contentsOf: digestsURL, encoding: .utf8).split(separator: "\n")
                .filter { !$0.contains(".no-final-newline.tree ") }.map(String.init)
            let contents = (kept + recordedDigests).joined(separator: "\n") + "\n"
            try contents.write(to: digestsURL, atomically: true, encoding: .utf8)
            return
        }

        let expected = try String(contentsOf: directory.appendingPathComponent(Self.noFinalNewlineFile), encoding: .utf8)
        if dumps != expected {
            let actual = FileManager.default.temporaryDirectory.appendingPathComponent(Self.noFinalNewlineFile)
            try dumps.write(to: actual, atomically: true, encoding: .utf8)
            XCTFail("\(Self.noFinalNewlineFile) differs from the recorded trees; this run's dump is at \(actual.path)")
        }
    }

    private static func readDigests(at url: URL) throws -> [String: String] {
        var digests: [String: String] = [:]
        for line in try String(contentsOf: url, encoding: .utf8).split(separator: "\n") {
            let fields = line.split(separator: " ")
            digests[String(fields[0])] = String(fields[1])
        }
        return digests
    }

    func testLineOffsetsCountCRLFAsOneBreakAndLoneCROrLFAsOne() {
        let cases: [(text: String, lineStarts: [Int])] = [
            ("", [0]),
            ("x", [0]),
            ("line\n", [0, 5]),
            ("a\r\nb\rc\nd", [0, 3, 5, 7]),
            ("\r\r\n\n", [0, 1, 3, 4]),
            ("é\r\n🇧🇷\n\r", [0, 4, 13, 14]),
            ("a\u{0301}\r\nb", [0, 5]),
            ("\n\u{0301}x", [0, 1]),
        ]
        for (text, lineStarts) in cases {
            let offsets = text.lineOffsets.map { text.utf8.distance(from: text.utf8.startIndex, to: $0) }
            XCTAssertEqual(offsets, lineStarts, "\(text.debugDescription)")
        }
    }

    func testDumpNamesEveryNodeWithItsSourceRangeInUTF8Bytes() async throws {
        let text = "é **b**\r\n"
        let dump = TreeDump.dump(try await Markdown(text: text).parse(), in: text)

        XCTAssertEqual(dump, """
        Root 1:1-1:8 @0..7
          Paragraph 1:1-1:8 @0..7
            Text value="é " 1:1-1:3 @0..2
            Strong 1:4-1:8 @3..7
              Text value="b" 1:6-1:6 @5..5

        """)
    }
}

/// The line endings each fixture is checked with.
enum LineEnding: String, CaseIterable {
    case lf, crlf, cr, mixed

    func apply(to text: String) -> String {
        switch self {
        case .lf: return text
        case .crlf: return text.replacingOccurrences(of: "\n", with: "\r\n")
        case .cr: return text.replacingOccurrences(of: "\n", with: "\r")
        case .mixed:
            // Line n ends with `\n`, `\r\n` or `\r` in turn.
            let endings = ["\n", "\r\n", "\r"]
            var out = ""
            for (index, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                if index > 0 { out += endings[(index - 1) % endings.count] }
                out += line
            }
            return out
        }
    }
}

/// A stable text form of a tree: one line per node, indented by depth, with its type, its
/// position as `line:column-line:column @startByte..endByte` and its other fields.
///
/// Offsets are UTF-8 distances from the start of the text, so the dump compares positions, not
/// the internal representation of `String.Index`.
enum TreeDump {

    static func dump(_ root: Root, in text: String) -> String {
        var out = ""
        write(root, depth: 0, in: text, to: &out)
        return out
    }

    private static func write(_ node: Node, depth: Int, in text: String, to out: inout String) {
        var line = String(repeating: "  ", count: depth) + "\(type(of: node))"
        var children: [Node] = []

        for case let (label?, value) in Mirror(reflecting: node).children {
            if let position = value as? Position {
                line += label == "position" ? " \(describe(position, in: text))" : " \(label)=\(describe(position, in: text))"
            } else if let position = value as? Position? {
                line += " \(label)=\(position.map { describe($0, in: text) } ?? "nil")"
            } else if let nodes = value as? [Node] {
                children += nodes
            } else {
                line += " \(label)=\(String(reflecting: value))"
            }
        }

        out += line + "\n"
        for child in children {
            write(child, depth: depth + 1, in: text, to: &out)
        }
    }

    /// A 64-bit FNV-1a digest of the dump, in hex, with its line count.
    static func digest(_ dump: String) -> String {
        var hash: UInt64 = 0xCBF29CE484222325
        for byte in dump.utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100000001B3
        }
        let lines = dump.utf8.reduce(0) { $1 == UInt8(ascii: "\n") ? $0 + 1 : $0 }
        let hex = String(hash, radix: 16)
        return String(repeating: "0", count: 16 - hex.count) + hex + "/\(lines)"
    }

    private static func describe(_ position: Position, in text: String) -> String {
        func offset(_ index: String.Index?) -> String {
            index.map { "\(text.utf8.distance(from: text.utf8.startIndex, to: $0))" } ?? "nil"
        }
        var result = "\(position.start.line):\(position.start.column)-\(position.end.line):\(position.end.column)"
        result += " @\(offset(position.start.offset))..\(offset(position.end.offset))"
        if let indent = position.indent {
            result += " indent=\(indent)"
        }
        return result
    }
}
