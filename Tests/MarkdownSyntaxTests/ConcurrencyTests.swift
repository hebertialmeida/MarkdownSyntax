//
//  ConcurrencyTests.swift
//  MarkdownSyntaxTests
//
//  Safety-harness coverage: concurrent parsing.
//
//  `CMNode` is `@unchecked Sendable` and `Markdown` is an actor, but parsing runs off the
//  main thread and the app re-parses during token streaming. cmark itself keeps global
//  state (extension registration via `cmark_gfm_core_extensions_ensure_registered`, the
//  syntax-extension registry), and each parse allocates/frees its own tree. If a
//  churn-reducing change introduced shared mutable wrapper state (a cache, a pool, a shared
//  owner), concurrent parsing would race.
//
//  These tests fan a large number of concurrent parses across the global executor, mixing
//  the same and different inputs, and assert every result is correct. Meant to be run under
//  Thread Sanitizer (`swift test --sanitize=thread`), which flags data races even when the
//  assertions happen to pass.
//

import XCTest
@testable import MarkdownSyntax

final class ConcurrencyTests: XCTestCase {

    private let sample = """
    # Concurrent 😀

    A paragraph with **bold**, _emphasis_, `code`, [link](https://example.com), and 日本語.

    - one
    - two

    > quote

    ```swift
    let x = 1
    ```
    """

    // MARK: - Many concurrent parses of the SAME input

    func testConcurrentParseSameInputManyTasks() async throws {
        let iterations = 400

        // Establish the expected HTML once, sequentially.
        let expectedHTML = try await Markdown(text: sample).renderHtml()

        try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<iterations {
                group.addTask { [sample] in
                    let markdown = try await Markdown(text: sample)
                    let root = await markdown.parse()
                    // Touch the value-typed tree.
                    XCTAssertFalse(root.children.isEmpty)
                    return try await markdown.renderHtml()
                }
            }
            for try await html in group {
                XCTAssertEqual(html, expectedHTML)
            }
        }
    }

    // MARK: - Many concurrent parses of DIFFERENT inputs

    func testConcurrentParseDifferentInputs() async throws {
        let iterations = 400

        try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for i in 0..<iterations {
                group.addTask {
                    let input = "# Heading \(i) 😀\n\nBody **\(i)** with `code\(i)` and 日本語\(i)."
                    let markdown = try await Markdown(text: input)
                    let root = await markdown.parse()
                    let heading = try XCTUnwrap(root.children.first as? Heading)
                    let text = try XCTUnwrap(heading.children.first as? Text)
                    return (i, text.value)
                }
            }
            for try await (i, headingText) in group {
                XCTAssertEqual(headingText, "Heading \(i) 😀")
            }
        }
    }

    // MARK: - Concurrent raw wrapper-graph walks over independent trees

    /// Each task builds its own document and walks the raw `CMNode` graph concurrently,
    /// stressing wrapper alloc/free and position computation off the main thread.
    func testConcurrentWrapperGraphWalks() async throws {
        let iterations = 300

        await withTaskGroup(of: Int.self) { group in
            for _ in 0..<iterations {
                group.addTask { [sample] in
                    guard let document = try? CMDocument(text: sample) else { return -1 }
                    var count = 0
                    func walk(_ node: CMNode) {
                        count += 1
                        _ = node.type
                        _ = node.literal
                        for child in node.children { walk(child) }
                    }
                    walk(document.node)
                    return count
                }
            }

            var counts: [Int] = []
            for await c in group { counts.append(c) }
            // Every independent walk of the same document must visit the same node count.
            XCTAssertEqual(Set(counts).count, 1, "Concurrent walks disagreed on node count: \(Set(counts))")
            XCTAssertFalse(counts.contains(-1))
        }
    }

    // MARK: - Concurrent parse + render mix

    func testConcurrentParseAndRenderMix() async throws {
        let iterations = 300

        try await withThrowingTaskGroup(of: Bool.self) { group in
            for i in 0..<iterations {
                group.addTask { [sample] in
                    let markdown = try await Markdown(text: sample)
                    if i % 2 == 0 {
                        let root = await markdown.parse()
                        return !root.children.isEmpty
                    } else {
                        let html = try await markdown.renderHtml()
                        return html.contains("Concurrent")
                    }
                }
            }
            for try await ok in group {
                XCTAssertTrue(ok)
            }
        }
    }
}
