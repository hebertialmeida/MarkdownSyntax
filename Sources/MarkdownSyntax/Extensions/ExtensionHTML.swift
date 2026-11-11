//
//  ExtensionHTML.swift
//  MarkdownSyntax
//

import cmark_gfm

/// The HTML extensions ask for, put into the cmark tree for one `renderHtml()` and taken out
/// after, so the tree stays cmark's own for every other reader and renderer.
///
/// A custom inline node goes where its parent can contain one. A GFM table cell can't, and holds
/// it inside an ``inlineHolder``: a node the cell can contain, which can contain a custom inline
/// node and which cmark's HTML renders as nothing of its own.
enum ExtensionHTML {

    /// What holds a custom inline node in a parent that can't contain one: cmark's attribute node
    /// (`^[text](attributes)`), whose HTML is its children's alone.
    static let inlineHolder = CMARK_NODE_ATTRIBUTE

    /// What takes a run of text nodes' place for the render: ranges of the source, and the HTML
    /// around them evaluated only when the document renders.
    enum Piece {
        /// The source's text there read as cmark reads text, rendered as cmark renders text.
        case text(Range<String.Index>)
        /// A custom inline node: `onEnter`, the source's text there read and rendered as text,
        /// `onExit`.
        case custom(onEnter: () -> String, onExit: () -> String, content: Range<String.Index>)
    }

    /// How a recognized anchor's nodes render.
    enum Kind {
        /// Inside one custom node.
        case wrap(onEnter: () -> String, onExit: () -> String)
        /// Replaced by these pieces (text nodes only), read as text in a table cell or not.
        case split([Piece], inCell: Bool)
        /// The anchor as it is, the siblings after it left out, and `rest` — the text the last
        /// of them keeps — in their place.
        case omit(rest: String?)
    }

    /// One recognized anchor's HTML: its nodes are the anchor, then the siblings it claimed.
    struct Request {
        let nodes: [UnsafeMutablePointer<cmark_node>]
        let isBlock: Bool
        let kind: Kind

        var anchor: UnsafeMutablePointer<cmark_node> {
            nodes[0]
        }
    }

    /// One request as applied.
    fileprivate struct Step {
        /// For a wrap, the node that takes the request's nodes' place: the custom node, or what
        /// holds it.
        let wrapper: UnsafeMutablePointer<cmark_node>?
        /// For a wrap, the custom node holding the request's nodes.
        var custom: UnsafeMutablePointer<cmark_node>?
        /// For a split, the new nodes in tree order.
        let created: [UnsafeMutablePointer<cmark_node>]
        /// For a split or an omission, the original nodes, out of the tree while it renders.
        let originals: [UnsafeMutablePointer<cmark_node>]
        /// For an omission, the anchor the originals follow.
        var anchor: UnsafeMutablePointer<cmark_node>?
    }

    /// The requests applied to the tree, in order, to take out with ``revert()``.
    struct Applied {
        fileprivate var steps: [Step] = []

        /// Puts the tree back as cmark made it, last step first.
        func revert() {
            for step in steps.reversed() {
                if let wrapper = step.wrapper, let custom = step.custom {
                    // Move the wrapped nodes back out, in order, then free the emptied wrapper.
                    while let child = cmark_node_first_child(custom) {
                        cmark_node_insert_before(wrapper, child)
                    }
                    cmark_node_free(wrapper)
                } else if let first = step.created.first {
                    for original in step.originals {
                        cmark_node_insert_before(first, original)
                    }
                    step.created.forEach { cmark_node_free($0) }
                } else if var previous = step.anchor {
                    for original in step.originals {
                        cmark_node_insert_after(previous, original)
                        previous = original
                    }
                }
            }
        }
    }

    /// Applies every request, its pieces read from `source`, the text parsed, as cmark reads text. On a failure the
    /// tree is put back and the error thrown.
    static func apply(_ requests: [Request], source: String) throws -> Applied {
        var applied = Applied()
        for request in requests {
            do {
                applied.steps.append(try apply(request, source: source))
            } catch {
                applied.revert()
                throw error
            }
        }
        return applied
    }

    private static func apply(_ request: Request, source: String) throws -> Step {
        let anchor = request.anchor
        guard let mem = anchor.pointee.content.mem else { throw CMDocumentError.renderError }

        switch request.kind {
        case let .wrap(onEnter, onExit):
            let (wrapper, inner) = request.isBlock
                ? try block(onEnter(), onExit(), mem)
                : try inline(onEnter(), onExit(), in: cmark_node_parent(anchor), mem)
            guard cmark_node_insert_before(anchor, wrapper) == 1 else {
                cmark_node_free(wrapper)
                throw CMDocumentError.renderError
            }
            let step = Step(wrapper: wrapper, custom: inner, created: [], originals: [])
            for node in request.nodes where cmark_node_append_child(inner, node) != 1 {
                Applied(steps: [step]).revert()
                throw CMDocumentError.renderError
            }
            return step

        case let .split(pieces, inCell):
            let literal = { TreeBuilder.literal(of: $0, in: source, inCell: inCell) }
            let parent = cmark_node_parent(anchor)
            var created: [UnsafeMutablePointer<cmark_node>] = []
            do {
                for piece in pieces {
                    switch piece {
                    case let .text(range):
                        created.append(try text(literal(range), mem))
                    case let .custom(onEnter, onExit, content):
                        let (outer, node) = try inline(onEnter(), onExit(), in: parent, mem)
                        created.append(outer)
                        if !content.isEmpty {
                            let child = try text(literal(content), mem)
                            guard cmark_node_append_child(node, child) == 1 else {
                                cmark_node_free(child)
                                throw CMDocumentError.renderError
                            }
                        }
                    }
                }
            } catch {
                created.forEach { cmark_node_free($0) }
                throw error
            }

            // Put the new nodes in, then take the originals out, kept for the revert.
            let step = Step(wrapper: nil, created: created, originals: request.nodes)
            for node in created where cmark_node_insert_before(anchor, node) != 1 {
                Applied(steps: [step]).revert()
                throw CMDocumentError.renderError
            }
            request.nodes.forEach { cmark_node_unlink($0) }
            return step

        case let .omit(rest):
            // The anchor stays; the siblings after it go out, kept for the revert, and the text
            // the last keeps takes their place.
            let originals = Array(request.nodes.dropFirst())
            let created = try rest.map { [try text($0, mem)] } ?? []
            let step = Step(wrapper: nil, created: created, originals: originals, anchor: anchor)
            for node in created where cmark_node_insert_after(anchor, node) != 1 {
                created.forEach { cmark_node_free($0) }
                throw CMDocumentError.renderError
            }
            originals.forEach { cmark_node_unlink($0) }
            return step
        }
    }

    /// A custom block, which takes its own place.
    private static func block(
        _ onEnter: String, _ onExit: String, _ mem: UnsafeMutablePointer<cmark_mem>
    ) throws -> (outer: UnsafeMutablePointer<cmark_node>, custom: UnsafeMutablePointer<cmark_node>) {
        let node = try custom(CMARK_NODE_CUSTOM_BLOCK, onEnter, onExit, mem)
        return (node, node)
    }

    /// A custom inline node for `parent`, and what takes its place there: itself, or an
    /// ``inlineHolder`` holding it where `parent` can't contain it.
    private static func inline(
        _ onEnter: String, _ onExit: String, in parent: UnsafeMutablePointer<cmark_node>?, _ mem: UnsafeMutablePointer<cmark_mem>
    ) throws -> (outer: UnsafeMutablePointer<cmark_node>, custom: UnsafeMutablePointer<cmark_node>) {
        let node = try custom(CMARK_NODE_CUSTOM_INLINE, onEnter, onExit, mem)
        guard let parent, !cmark_node_can_contain_type(parent, CMARK_NODE_CUSTOM_INLINE) else { return (node, node) }
        guard let holder = cmark_node_new_with_mem(inlineHolder, mem) else {
            cmark_node_free(node)
            throw CMDocumentError.renderError
        }
        guard cmark_node_append_child(holder, node) == 1 else {
            cmark_node_free(node)
            cmark_node_free(holder)
            throw CMDocumentError.renderError
        }
        return (holder, node)
    }

    private static func custom(
        _ type: cmark_node_type, _ onEnter: String, _ onExit: String, _ mem: UnsafeMutablePointer<cmark_mem>
    ) throws -> UnsafeMutablePointer<cmark_node> {
        guard let node = cmark_node_new_with_mem(type, mem) else { throw CMDocumentError.renderError }
        guard cmark_node_set_on_enter(node, onEnter) == 1, cmark_node_set_on_exit(node, onExit) == 1 else {
            cmark_node_free(node)
            throw CMDocumentError.renderError
        }
        return node
    }

    private static func text(_ literal: String, _ mem: UnsafeMutablePointer<cmark_mem>) throws -> UnsafeMutablePointer<cmark_node> {
        guard let node = cmark_node_new_with_mem(CMARK_NODE_TEXT, mem) else { throw CMDocumentError.renderError }
        guard cmark_node_set_literal(node, literal) == 1 else {
            cmark_node_free(node)
            throw CMDocumentError.renderError
        }
        return node
    }
}
