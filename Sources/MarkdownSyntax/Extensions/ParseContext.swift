//
//  ParseContext.swift
//  MarkdownSyntax
//

import cmark_gfm

/// A cmark node met while the tree is built, as a ``MarkdownExtension`` reads it.
///
/// A source node reads the cmark tree in place: it is valid only during the recognizer call
/// that received it, and must not be stored. Its positions come from the ``ParseContext``.
public struct SourceNode: Equatable {

    let view: CMNodeView

    /// The kind of node the tree reads this as, or `nil` for a cmark node it has no node for.
    public var kind: NodeKind? {
        NodeKind(view.type)
    }

    /// The literal cmark keeps for text, code, code blocks and HTML, after it resolved entities
    /// and escapes. Read the source through ``ParseContext/range(of:)`` to see what was written.
    public var literal: String? {
        view.literal
    }

    /// A fenced code block's info string, the text after its opening fence.
    public var fenceInfo: String? {
        view.fencedCodeInfo
    }

    /// A heading's level, 1 to 6.
    public var headingLevel: Int {
        view.headingLevel
    }

    /// The node that contains this one.
    public var parent: SourceNode? {
        view.parent.map(SourceNode.init(view:))
    }

    /// The sibling after this one.
    public var next: SourceNode? {
        view.next.map(SourceNode.init(view:))
    }

    /// The sibling before this one.
    public var previous: SourceNode? {
        view.previous.map(SourceNode.init(view:))
    }

    /// The first child.
    public var firstChild: SourceNode? {
        view.firstChild.map(SourceNode.init(view:))
    }

    /// Two source nodes are equal when they read the same cmark node.
    public static func == (lhs: SourceNode, rhs: SourceNode) -> Bool {
        lhs.view.pointer == rhs.view.pointer
    }
}

/// What a ``MarkdownExtension`` gets for one anchor: the node, its source, and the tools to read
/// it, claim the siblings after it, and give it HTML.
///
/// A context is valid only during the recognizer call that received it. Everything it builds
/// carries positions in the source, so ranges always come from what was written (see
/// <doc:Ranges>).
public struct ParseContext {

    let builder: TreeBuilder

    /// Whether the anchor was met as block content, rather than phrasing content.
    let isBlock: Bool

    /// The node this extension is offered: its kind is one of the extension's anchors.
    public let anchor: SourceNode

    /// The last sibling claimed, if any.
    private var lastClaimed: CMNodeView?

    /// The nodes the HTML asked for in this call covers (the anchor and the siblings claimed),
    /// and what it asked for. Committed only if the recognizer returns nodes.
    private var htmlNodes: [CMNodeView]?
    private var htmlWrap: (onEnter: () -> String, onExit: () -> String)?
    private var htmlSplit: (run: Range<String.Index>, end: String.Index, pieces: [ExtensionHTML.Piece], inCell: Bool)?
    /// For ``omitHTML(_:)``: the text the last sibling claimed keeps after the syntax, if any.
    private var htmlOmit: String??

    /// The anchor's own reading, once a recognizer asked for it, so it is built once.
    private var anchorBlock: BlockContent??
    private var anchorPhrasing: PhrasingContent??

    init(builder: TreeBuilder, anchor: CMNodeView, isBlock: Bool) {
        self.builder = builder
        self.anchor = SourceNode(view: anchor)
        self.isBlock = isBlock
    }

    // MARK: Source

    /// The whole Markdown source being parsed.
    public var source: String {
        builder.text
    }

    /// The source range a node covers, or `nil` when cmark gave it no usable position.
    public func range(of node: SourceNode) -> Range<String.Index>? {
        builder.range(of: node.view)
    }

    /// The position a node has in the tree.
    public func position(of node: SourceNode) -> Position {
        builder.position(for: node.view)
    }

    /// The position of a source range, with the line, column and offset of its first and last
    /// character, as every node in the tree has. `nil` when the range is empty or outside the
    /// source.
    public func position(of range: Range<String.Index>) -> Position? {
        builder.position(of: range)
    }

    /// The text cmark makes of a source range when it reads it as text, as in
    /// ``SourceNode/literal``: a backslash before ASCII punctuation gives that punctuation, and an
    /// entity or numeric character reference gives the character it names.
    ///
    /// For syntax written inside text whose literal differs from its source: find the syntax in
    /// the source, so its ranges are right, and take the text a reader sees from here. In
    /// `see [[Caf&eacute;]]`, the source between the brackets reads as `Café`. In a GFM table
    /// cell, as the anchor's is, `\|` reads as `|` first, as the table reads it. See <doc:Ranges>.
    ///
    /// Only escapes and references are read: emphasis, code spans, links and line ends in the
    /// range stay as written. Pass a range of the anchor or of the siblings claimed.
    public func literal(of range: Range<String.Index>) -> String {
        builder.literal(of: range, inCell: builder.enclosingCell(of: anchor.view) != nil)
    }

    // MARK: Siblings

    /// The siblings claimed so far, in order.
    public var claimed: [SourceNode] {
        guard let lastClaimed else { return [] }
        var nodes: [SourceNode] = []
        var cursor = anchor.view.next
        while let node = cursor {
            nodes.append(SourceNode(view: node))
            if node.pointer == lastClaimed.pointer { break }
            cursor = node.next
        }
        return nodes
    }

    /// The sibling after the anchor and every sibling claimed so far.
    public var nextUnclaimed: SourceNode? {
        (lastClaimed ?? anchor.view).next.map(SourceNode.init(view:))
    }

    /// Claims every sibling after the anchor up to and including `sibling`: the tree build skips
    /// them, and the nodes you return stand for them too.
    ///
    /// Claim before asking for HTML. A claim is kept only if the recognizer returns nodes.
    ///
    /// - Precondition: `sibling` follows the anchor and every sibling claimed so far, and no HTML
    ///   was asked for yet in this call.
    public mutating func claim(through sibling: SourceNode) {
        precondition(htmlNodes == nil, "claim(through:) must come before wrapHTML")
        var cursor = (lastClaimed ?? anchor.view).next
        while let node = cursor {
            if node.pointer == sibling.view.pointer {
                lastClaimed = node
                return
            }
            cursor = node.next
        }
        preconditionFailure("claim(through:) takes a sibling after the anchor and after every sibling already claimed")
    }

    /// Where the tree build continues once this anchor is recognized.
    var resume: CMNodeView? {
        (lastClaimed ?? anchor.view).next
    }

    /// Forgets this call's claims and HTML, before the next extension is offered the anchor.
    mutating func reset() {
        lastClaimed = nil
        htmlNodes = nil
        htmlWrap = nil
        htmlSplit = nil
        htmlOmit = nil
    }

    // MARK: Reading nodes

    /// A block node as the tree holds it without this extension, other extensions inside it
    /// recognized as usual. `nil` for a node the tree leaves out.
    ///
    /// The anchor is read once however often you ask, and if no extension recognizes it, that
    /// reading is the one the tree keeps.
    public mutating func plainBlock(_ node: SourceNode) -> BlockContent? {
        guard node == anchor else { return builder.plainBlock(node.view) }
        if let anchorBlock { return anchorBlock }
        let content = builder.plainBlock(node.view)
        anchorBlock = .some(content)
        return content
    }

    /// A phrasing node as the tree holds it without this extension, other extensions inside it
    /// recognized as usual. `nil` for a node the tree leaves out.
    ///
    /// The anchor is read once however often you ask, and if no extension recognizes it, that
    /// reading is the one the tree keeps.
    public mutating func plainPhrasing(_ node: SourceNode) -> PhrasingContent? {
        guard node == anchor else { return builder.plainPhrasing(node.view) }
        if let anchorPhrasing { return anchorPhrasing }
        let content = builder.plainPhrasing(node.view)
        anchorPhrasing = .some(content)
        return content
    }

    /// A node's children read as block content, with extensions recognized.
    public func blocks(in node: SourceNode) -> [BlockContent] {
        builder.blocks(from: node.view.firstChild)
    }

    /// A node's children read as phrasing content, with extensions recognized.
    public func phrasing(in node: SourceNode) -> [PhrasingContent] {
        builder.phrasing(from: node.view.firstChild)
    }

    /// The anchor's reading, if a recognizer asked for it.
    var cachedBlock: BlockContent?? {
        anchorBlock
    }

    var cachedPhrasing: PhrasingContent?? {
        anchorPhrasing
    }

    // MARK: HTML

    /// Renders the anchor and the siblings claimed so far between `onEnter` and `onExit` in
    /// ``Markdown/renderHtml()``.
    ///
    /// cmark renders the nodes inside as usual, so the HTML is cmark's with yours around it. For
    /// the render the nodes go into a cmark custom block (an anchor met as block content) or
    /// custom inline node (met as phrasing content), and come out of it after. See
    /// <doc:HTMLOutput>.
    ///
    /// `onEnter` and `onExit` are evaluated only when the document is rendered, so a parse that
    /// never renders HTML never builds them.
    ///
    /// - Returns: `false`, and nothing is asked for, when HTML was already asked for in this call
    ///   or the anchor's parent can't contain a custom node (a list holds only items). Any inline
    ///   parent can, a GFM table cell included.
    @discardableResult
    public mutating func wrapHTML(onEnter: @autoclosure @escaping () -> String, onExit: @autoclosure @escaping () -> String) -> Bool {
        let nodes = [anchor.view] + claimed.map(\.view)
        guard htmlNodes == nil, builder.canWrap(nodes[0], inBlock: isBlock) else { return false }
        htmlNodes = nodes
        htmlWrap = (onEnter, onExit)
        return true
    }

    /// Renders part of the anchor's text between `onEnter` and `onExit` in
    /// ``Markdown/renderHtml()``, and leaves the rest of `syntax` out of the HTML.
    ///
    /// For syntax written inside text, such as `==marked==`: `syntax` is the whole of it,
    /// delimiters included, and `content` the part shown between `onEnter` and `onExit`. The
    /// text around renders as before. Call it once for each occurrence, in source order. See
    /// <doc:HTMLOutput>.
    ///
    /// `onEnter` and `onExit` are evaluated only when the document is rendered, so a parse that
    /// never renders HTML never builds them.
    ///
    /// The text around and `content` render as cmark reads them (``literal(of:)``), so escapes
    /// and entity references in them, and `\|` in a GFM table cell, read as they do without the
    /// extension.
    ///
    /// - Returns: `false`, and nothing is asked for, unless the anchor was met as phrasing
    ///   content; the anchor and the siblings claimed so far are adjacent text nodes whose
    ///   literal is their source read as text (``literal(of:)``); `syntax` lies in their source
    ///   after any occurrence given before and `content` lies in `syntax`, and no escape or
    ///   reference spans a bound of either; no ``wrapHTML(onEnter:onExit:)`` was asked for; and
    ///   their parent can contain a custom node, as any inline parent can.
    @discardableResult
    public mutating func wrapHTML(
        _ content: Range<String.Index>,
        in syntax: Range<String.Index>,
        onEnter: @autoclosure @escaping () -> String,
        onExit: @autoclosure @escaping () -> String
    ) -> Bool {
        guard !isBlock, htmlWrap == nil, htmlOmit == nil else { return false }
        if htmlSplit == nil {
            let nodes = [anchor.view] + claimed.map(\.view)
            let inCell = builder.enclosingCell(of: nodes[0]) != nil
            guard
                let run = builder.literalTextRun(nodes, inCell: inCell),
                builder.canWrap(nodes[0], inBlock: false)
            else { return false }
            htmlNodes = nodes
            htmlSplit = (run, run.lowerBound, [], inCell)
        }
        guard
            var split = htmlSplit,
            split.end <= syntax.lowerBound, syntax.upperBound <= split.run.upperBound,
            syntax.lowerBound <= content.lowerBound, content.upperBound <= syntax.upperBound,
            [syntax.lowerBound, content.lowerBound, content.upperBound, syntax.upperBound]
                .allSatisfy({ builder.cutsCleanly(split.run, at: $0, inCell: split.inCell) })
        else { return false }

        if split.end < syntax.lowerBound {
            split.pieces.append(.text(split.end..<syntax.lowerBound))
        }
        split.pieces.append(.custom(onEnter: onEnter, onExit: onExit, content: content))
        split.end = syntax.upperBound
        htmlSplit = split
        return true
    }

    /// Leaves `syntax` — written in the siblings claimed, right after the anchor — out of
    /// ``Markdown/renderHtml()``. The anchor renders as cmark renders it.
    ///
    /// For syntax written right after a node that belongs to it, such as an attribute block
    /// after an image, `![Fox](fox.png){width=50%}`: claim the siblings that hold it, then ask
    /// for this. `syntax` opens where the first sibling claimed does. The siblings it covers
    /// whole don't render; a text sibling it ends inside renders only its text after it, as
    /// cmark renders text. Whatever cmark read inside the syntax — emphasis, a link, an entity
    /// or an escape — goes with it, and no custom node is made. See <doc:HTMLOutput>.
    ///
    /// - Returns: `false`, and nothing is asked for, unless the anchor was met as phrasing
    ///   content; siblings were claimed; `syntax` is not empty, opens where the first of them
    ///   does, and ends inside the last, and every one between ends inside it or has no place
    ///   (a soft line break); a last sibling that runs past it is text whose literal ends with
    ///   the source after it — but for the spaces and tabs cmark drops right before a line end;
    ///   and no other HTML was asked for in this call.
    @discardableResult
    public mutating func omitHTML(_ syntax: Range<String.Index>) -> Bool {
        let siblings = claimed.map(\.view)
        guard
            !isBlock, htmlNodes == nil, !syntax.isEmpty,
            let first = siblings.first, let last = siblings.last,
            builder.range(of: first)?.lowerBound == syntax.lowerBound,
            let end = builder.range(of: last)?.upperBound, end >= syntax.upperBound,
            // One cmark gave no place, such as a soft line break, lies between two that have one.
            siblings.dropLast().allSatisfy({ builder.range(of: $0).map { $0.upperBound <= syntax.upperBound } ?? true })
        else { return false }
        var rest: String?
        if end > syntax.upperBound {
            let text = builder.text
            var after = text[syntax.upperBound..<end]
            guard last.type == .text, let literal = last.literal else { return false }
            if !literal.hasSuffix(after), text.utf8[end...].first.map({ $0 == 0x0A || $0 == 0x0D }) == true {
                // Right before a line end cmark drops the spaces and tabs from the text's literal,
                // and keeps them in its place.
                after = after.prefix(upTo: after.utf8.lastIndex { $0 != 0x20 && $0 != 0x09 }.map { after.utf8.index(after: $0) } ?? after.startIndex)
            }
            guard literal.hasSuffix(after) else { return false }
            rest = after.isEmpty ? nil : String(after)
        }
        htmlNodes = [anchor.view] + siblings
        htmlOmit = .some(rest)
        return true
    }

    /// The HTML asked for in this call, if any.
    var html: ExtensionHTML.Request? {
        guard let htmlNodes else { return nil }
        let nodes = htmlNodes.map(\.pointer)
        if let htmlOmit {
            return ExtensionHTML.Request(nodes: nodes, isBlock: false, kind: .omit(rest: htmlOmit))
        }
        if let htmlWrap {
            return ExtensionHTML.Request(nodes: nodes, isBlock: isBlock, kind: .wrap(onEnter: htmlWrap.onEnter, onExit: htmlWrap.onExit))
        }
        guard var split = htmlSplit, !split.pieces.isEmpty else { return nil }
        if split.end < split.run.upperBound {
            split.pieces.append(.text(split.end..<split.run.upperBound))
        }
        return ExtensionHTML.Request(nodes: nodes, isBlock: false, kind: .split(split.pieces, inCell: split.inCell))
    }
}
