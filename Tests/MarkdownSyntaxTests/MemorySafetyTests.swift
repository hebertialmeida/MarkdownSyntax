//
//  MemorySafetyTests.swift
//  MarkdownSyntaxTests
//
//  Safety-harness coverage: use-after-free / double-free of the hand-rolled cmark
//  memory model in `CMNode`.
//
//  Invariant under test: every derived `CMNode` wrapper (`next`, `firstChild`, `parent`,
//  `children`, iterator nodes, …) strongly retains the *root owner* node through
//  `referencedMemoryOwner`. As long as any wrapper is held, the underlying cmark tree
//  must stay alive and readable; only the owning root frees it, exactly once, in `deinit`.
//
//  A future optimization that reduces wrapper-object churn (e.g. caching, or not threading
//  the owner through every wrapper) could break this ownership chain and produce a
//  use-after-free or double-free. These tests exercise the chain so such a regression
//  surfaces here — run them under Address Sanitizer (`swift test --sanitize=address`) to
//  catch the memory error even when the logical assertions would still pass by luck.
//

import XCTest
@testable import MarkdownSyntax

final class MemorySafetyTests: XCTestCase {

    private let sample = """
    # Title 😀

    A paragraph with **bold**, _emphasis_, `code`, and a [link](https://example.com).

    - item one
    - item two with `inline`

    > a blockquote with 日本語

    | a | b |
    |---|---|
    | 1 | 2 |

    ```swift
    let x = 1
    ```
    """

    // MARK: - Retained nested nodes outlive the document/owner

    /// Grab nested `CMNode`s, drop the owning `CMDocument`, then read the retained nodes.
    /// Must not crash and must return the correct values — the retained wrappers keep the
    /// root owner (and thus the cmark tree) alive via `referencedMemoryOwner`.
    func testRetainedChildNodesOutliveDocument() throws {
        var document: CMDocument? = try CMDocument(text: sample)

        // Reach several levels deep and hold onto leaf wrappers.
        let heading = try XCTUnwrap(document?.node.firstChild)
        let headingText = try XCTUnwrap(heading.firstChild)
        let paragraph = try XCTUnwrap(heading.next)
        let paragraphChildren = paragraph.children

        // Drop the document (and its owner-root wrapper reference held by CMDocument).
        document = nil

        // Access retained nodes AFTER the document is gone.
        XCTAssertEqual(heading.type, .heading)
        XCTAssertEqual(headingText.literal, "Title 😀")
        XCTAssertEqual(paragraph.type, .paragraph)
        XCTAssertFalse(paragraphChildren.isEmpty)
        // Walking further from a retained node must still work.
        XCTAssertNotNil(paragraph.firstChild?.next)
    }

    /// Hold only a *single* deep leaf node, drop everything else, then read it.
    /// This is the tightest form of the invariant: one retained wrapper must be enough
    /// to keep the entire tree alive.
    func testSingleDeepNodeKeepsTreeAlive() throws {
        func deepestText() throws -> CMNode {
            let document = try CMDocument(text: sample)
            let all = document.node.getAll(where: { $0.type == .text })
            return try XCTUnwrap(all.first)
            // `document` goes out of scope here; only the returned node survives.
        }

        let leaf = try deepestText()
        // The owner is reachable and alive through referencedMemoryOwner.
        XCTAssertNotNil(leaf.internalMemoryOwner)
        XCTAssertNotNil(leaf.literal)
        // Navigate upward to the root through the retained tree.
        var cursor: CMNode? = leaf
        var hops = 0
        while let parent = cursor?.parent {
            cursor = parent
            hops += 1
        }
        XCTAssertEqual(cursor?.type, .document)
        XCTAssertGreaterThan(hops, 0)
    }

    /// The Swift AST returned by `parse()` is fully value-typed and must not depend on any
    /// cmark memory after the parser/document are gone.
    func testParsedASTIndependentOfCmarkMemory() async throws {
        func parseAndDrop() async throws -> Root {
            let markdown = try await Markdown(text: sample)
            return await markdown.parse()
            // `markdown` (and its CMDocument) deallocate here.
        }

        let root = try await parseAndDrop()
        // Read deep into the value-typed tree after the source document is gone.
        let heading = try XCTUnwrap(root.children.first as? Heading)
        XCTAssertEqual(heading.depth, .h1)
        XCTAssertNotNil(heading.position.range)
    }

    // MARK: - Iterator lifetime & reset

    /// Fully enumerate a document, then reset and re-enumerate. The iterator retains its
    /// owner node; nodes yielded during enumeration must be readable.
    func testIteratorEnumerateResetReenumerate() throws {
        let document = try CMDocument(text: sample)
        let iterator = try XCTUnwrap(document.node.iterator)

        var firstPassTypes: [CMNodeType] = []
        try iterator.enumerate { node, event in
            if event == .enter { firstPassTypes.append(node.type) }
            return false
        }
        XCTAssertFalse(firstPassTypes.isEmpty)
        XCTAssertEqual(firstPassTypes.first, .document)

        // Reset back to the root and enumerate again. reset(to:eventType:.enter) leaves the
        // iterator positioned *at* the document-enter event, and enumerate advances with
        // cmark_iter_next before yielding — so the re-walk yields the same sequence minus the
        // already-consumed leading .document enter. The point is that reset + re-enumeration
        // works and every yielded node stays readable.
        iterator.reset(to: document.node, eventType: .enter)
        var secondPassTypes: [CMNodeType] = []
        try iterator.enumerate { node, event in
            if event == .enter { secondPassTypes.append(node.type) }
            return false
        }
        XCTAssertEqual(secondPassTypes, Array(firstPassTypes.dropFirst()))
        XCTAssertFalse(secondPassTypes.isEmpty)
    }

    /// Nodes captured from inside `enumerate` must remain valid after the iterator is gone,
    /// because each yielded node retains the owner.
    func testIteratorYieldedNodesOutliveIterator() throws {
        let document = try CMDocument(text: sample)
        var captured: [CMNode] = []

        do {
            let iterator = try XCTUnwrap(document.node.iterator)
            try iterator.enumerate { node, event in
                if event == .enter, node.type == .text {
                    captured.append(node)
                }
                return false
            }
            // iterator deallocates at the end of this scope.
        }

        XCTAssertFalse(captured.isEmpty)
        for node in captured {
            XCTAssertNotNil(node.literal)  // read after the iterator is freed
        }
    }

    // MARK: - Alloc/free churn under tight re-parse loops

    /// Re-parse the *same* input hundreds of times. Each iteration allocates and frees a
    /// full wrapper tree; this stresses the deinit/free path for double-frees.
    func testTightReparseSameInputLoop() async throws {
        for _ in 0..<500 {
            let markdown = try await Markdown(text: sample)
            let root = await markdown.parse()
            XCTAssertFalse(root.children.isEmpty)
        }
    }

    /// Re-parse *different* inputs in a tight loop (mimics per-keystroke re-parsing).
    func testTightReparseDifferentInputLoop() async throws {
        for i in 0..<500 {
            let input = "# Heading \(i) 😀\n\nBody **\(i)** with `code\(i)` and 日本語\(i)."
            let markdown = try await Markdown(text: input)
            let root = await markdown.parse()
            let heading = try XCTUnwrap(root.children.first as? Heading)
            let text = try XCTUnwrap(heading.children.first as? Text)
            XCTAssertEqual(text.value, "Heading \(i) 😀")
        }
    }

    /// Churn the raw wrapper graph (no value-typed parse) in a loop: repeatedly walk
    /// `firstChild`/`next`/`parent`/`children`, allocating and freeing many wrappers over
    /// one shared tree, then let the owner drop.
    func testWrapperGraphChurnLoop() throws {
        let document = try CMDocument(text: sample)
        for _ in 0..<2000 {
            var count = 0
            func walk(_ node: CMNode) {
                count += 1
                for child in node.children { walk(child) }
                _ = node.parent
                _ = node.next
                _ = node.previous
                _ = node.lastChild
            }
            walk(document.node)
            XCTAssertGreaterThan(count, 0)
        }
    }
}
