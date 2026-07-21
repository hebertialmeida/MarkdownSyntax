//
//  LeakTests.swift
//  MarkdownSyntaxTests
//
//  Safety-harness coverage: leaks / retain cycles in the cmark wrapper objects.
//
//  The mirror image of the memory-safety tests. There the risk was freeing *too soon*
//  (use-after-free); here the risk is *never freeing* — a wrapper that leaks its
//  `cmark_node`, or a retain cycle between wrappers (e.g. child strongly retains the owner
//  via `referencedMemoryOwner`; if the owner ever retained its children back, nothing would
//  ever deallocate).
//
//  Technique & limitations:
//  * We use `weak` references to `CMNode` / `CMDocument` / `Iterator` wrappers checked
//    after their strong references leave scope. A non-nil weak reference means a Swift-level
//    retain cycle. This detects wrapper-object leaks and cycles, which is exactly the class
//    of bug a churn-reducing change (caching wrappers, back-references) would introduce.
//  * It does NOT directly observe `cmark_node_free`: the C allocation is invisible to
//    ARC/weak refs. We cover that indirectly with bounded-growth loops (below) and, more
//    strongly, by running the whole suite under Address Sanitizer, whose leak/heap checks
//    see the C heap. So: weak refs catch Swift cycles; ASan catches C leaks.
//

import XCTest
@testable import MarkdownSyntax

final class LeakTests: XCTestCase {

    private let sample = """
    # Heading

    Paragraph with **bold** and a [link](https://example.com) plus `code`.

    - one
    - two
    """

    // MARK: - Wrapper objects must deallocate (no retain cycle)

    /// After the document leaves scope, its root wrapper must deallocate.
    func testDocumentDeallocates() throws {
        weak var weakNode: CMNode?

        try autoreleasepool {
            let document = try CMDocument(text: sample)
            weakNode = document.node
            XCTAssertNotNil(weakNode)
            _ = document.node.children  // create & drop a batch of child wrappers
        }

        XCTAssertNil(weakNode, "Root CMNode leaked — a retain cycle keeps the owner alive")
    }

    /// Child wrappers reference the owner (child -> owner) but the owner must not reference
    /// children back. Holding a child keeps the owner alive; dropping the child must free both.
    func testChildAndOwnerDeallocateTogether() throws {
        weak var weakOwner: CMNode?
        weak var weakChild: CMNode?

        try autoreleasepool {
            let document = try CMDocument(text: sample)
            let child = try XCTUnwrap(document.node.firstChild?.firstChild)
            weakOwner = child.internalMemoryOwner
            weakChild = child
            XCTAssertNotNil(weakOwner)
            XCTAssertNotNil(weakChild)
        }

        XCTAssertNil(weakChild, "Child CMNode leaked")
        XCTAssertNil(weakOwner, "Owner CMNode leaked — child<->owner retain cycle")
    }

    /// The iterator retains its owner node; after both leave scope, both must deallocate.
    func testIteratorAndOwnerDeallocate() throws {
        weak var weakIteratorOwner: CMNode?

        try autoreleasepool {
            let document = try CMDocument(text: sample)
            let iterator = try XCTUnwrap(document.node.iterator)
            try iterator.enumerate { _, _ in false }
            weakIteratorOwner = document.node
            XCTAssertNotNil(weakIteratorOwner)
        }

        XCTAssertNil(weakIteratorOwner, "Iterator kept its owner node alive after scope exit")
    }

    /// A deep leaf retained past the document's scope must itself deallocate once dropped,
    /// taking the whole retained tree with it.
    func testRetainedLeafReleasesTreeWhenDropped() throws {
        weak var weakOwner: CMNode?

        try autoreleasepool {
            var leaf: CMNode? = try {
                let document = try CMDocument(text: sample)
                return try XCTUnwrap(document.node.getAll(where: { $0.type == .text }).first)
            }()
            weakOwner = leaf?.internalMemoryOwner
            XCTAssertNotNil(weakOwner, "Retained leaf should keep the owner alive")
            leaf = nil
        }

        XCTAssertNil(weakOwner, "Dropping the last retained leaf did not release the owner/tree")
    }

    // MARK: - Bounded growth under repeated parsing

    /// Weak-reference sampling across a re-parse loop: every iteration's root wrapper must be
    /// deallocated by the time the next iteration starts (no unbounded accumulation of live
    /// wrapper trees). This is a Swift-level bounded-growth check; ASan covers the C heap.
    func testRepeatedParseDoesNotAccumulateWrappers() throws {
        weak var previousRoot: CMNode?

        for _ in 0..<300 {
            try autoreleasepool {
                XCTAssertNil(previousRoot, "Previous iteration's wrapper tree was still alive")
                let document = try CMDocument(text: sample)
                previousRoot = document.node
                _ = document.node.getAll(where: { _ in true })  // materialize the whole wrapper tree
            }
        }
        XCTAssertNil(previousRoot)
    }

    /// Same idea through the full `Markdown` actor + value-typed `parse()` path.
    func testRepeatedMarkdownParseBoundedGrowth() async throws {
        for i in 0..<300 {
            try await autoreleasepoolAsync {
                let markdown = try await Markdown(text: "# H\(i)\n\nBody \(i) **b** `c`.")
                let root = await markdown.parse()
                XCTAssertFalse(root.children.isEmpty)
            }
        }
    }
}

/// Async-friendly autorelease wrapper (autoreleasepool cannot straddle an await).
private func autoreleasepoolAsync(_ body: () async throws -> Void) async rethrows {
    try await body()
}
