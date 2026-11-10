//
//  ExtensionHTML.swift
//  MarkdownSyntax
//

import cmark_gfm

/// The HTML extensions ask for, put into the cmark tree for one `renderHtml()` and taken out
/// after, so the tree stays cmark's own for every other reader and renderer.
enum ExtensionHTML {

    /// What takes a run of text nodes' place for the render: ranges of the source, and the HTML
    /// around them evaluated only when the document renders.
    enum Piece {
        /// The source's text there, rendered as cmark renders text.
        case text(Range<String.Index>)
        /// A custom inline node: `onEnter`, the source's text there rendered as text, `onExit`.
        case custom(onEnter: () -> String, onExit: () -> String, content: Range<String.Index>)
    }

    /// How a recognized anchor's nodes render.
    enum Kind {
        /// Inside one custom node.
        case wrap(onEnter: () -> String, onExit: () -> String)
        /// Replaced by these pieces (text nodes only).
        case split([Piece])
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
        /// For a wrap, the custom node holding the request's nodes.
        let wrapper: UnsafeMutablePointer<cmark_node>?
        /// For a split, the new nodes in tree order.
        let created: [UnsafeMutablePointer<cmark_node>]
        /// For a split, the original text nodes, out of the tree while it renders.
        let originals: [UnsafeMutablePointer<cmark_node>]
    }

    /// The requests applied to the tree, in order, to take out with ``revert()``.
    struct Applied {
        fileprivate var steps: [Step] = []

        /// Puts the tree back as cmark made it, last step first.
        func revert() {
            for step in steps.reversed() {
                if let wrapper = step.wrapper {
                    // Move the wrapped nodes back out, in order, then free the empty custom node.
                    while let child = cmark_node_first_child(wrapper) {
                        cmark_node_insert_before(wrapper, child)
                    }
                    cmark_node_free(wrapper)
                } else if let first = step.created.first {
                    for original in step.originals {
                        cmark_node_insert_before(first, original)
                    }
                    step.created.forEach { cmark_node_free($0) }
                }
            }
        }
    }

    /// Applies every request, its pieces read from `source`, the text parsed. On a failure the
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
            let wrapper = try custom(request.isBlock ? CMARK_NODE_CUSTOM_BLOCK : CMARK_NODE_CUSTOM_INLINE, onEnter(), onExit(), mem)
            guard cmark_node_insert_before(anchor, wrapper) == 1 else {
                cmark_node_free(wrapper)
                throw CMDocumentError.renderError
            }
            let step = Step(wrapper: wrapper, created: [], originals: [])
            for node in request.nodes where cmark_node_append_child(wrapper, node) != 1 {
                Applied(steps: [step]).revert()
                throw CMDocumentError.renderError
            }
            return step

        case let .split(pieces):
            var created: [UnsafeMutablePointer<cmark_node>] = []
            do {
                for piece in pieces {
                    switch piece {
                    case let .text(range):
                        created.append(try text(String(source[range]), mem))
                    case let .custom(onEnter, onExit, content):
                        let node = try custom(CMARK_NODE_CUSTOM_INLINE, onEnter(), onExit(), mem)
                        created.append(node)
                        if !content.isEmpty {
                            let child = try text(String(source[content]), mem)
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
        }
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
