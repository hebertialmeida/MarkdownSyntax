//
//  Markdown.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

import cmark_gfm

/// Markdown parser
public final actor Markdown {

    /// The current footnote index.
    private var footnoteIndex: Int = 0

    private var lineOffsets: [String.Index] = []

    private var text = ""

    /// The root node of the document.
    public var document: CMDocument

    /// The syntax extensions, by anchor type.
    let syntax: SyntaxRegistry

    /// With syntax extensions, the tree and its HTML requests, built once.
    private var built: (root: Root, html: [ExtensionHTML.Request])?

    // MARK: Init

    /// Init a parser.
    ///
    /// - Parameters:
    ///     - text: The input string.
    ///     - startingFootnoteIndex: The index footnote should start.
    ///     - options: The document options.
    ///     - extensions: gfm extensions to enable.
    /// - Throws:
    ///     `CMDocumentError.parsingError` if an invalid event type is encountered.
    /// - Returns:
    ///     The initialized parser.
    public init(text: String, startingFootnoteIndex: Int = 0, options: CMDocumentOption = [.sourcepos, .strikethroughDoubleTilde, .footnotes], extensions: CMExtensionOption = [.all]) async throws {
        try await self.init(text: text, startingFootnoteIndex: startingFootnoteIndex, options: options, extensions: extensions, syntaxExtensions: [])
    }

    /// Init a parser that recognizes syntax extensions of your own.
    ///
    /// Each extension is offered the nodes of its anchor types while the tree is built, and
    /// returns its own nodes for the syntax it recognizes (see ``MarkdownExtension``). With no
    /// syntax extensions, the parser is the one ``init(text:startingFootnoteIndex:options:extensions:)``
    /// makes.
    ///
    /// With syntax extensions, ``parse()`` builds the tree once and returns that tree on every
    /// call, and ``renderHtml()`` includes the HTML the extensions give, whether or not
    /// ``parse()`` ran before it.
    ///
    /// - Parameters:
    ///     - text: The input string.
    ///     - startingFootnoteIndex: The index footnote should start.
    ///     - options: The document options.
    ///     - extensions: gfm extensions to enable.
    ///     - syntaxExtensions: Your syntax extensions. When two share an anchor type, the one
    ///       given first is tried first.
    /// - Throws:
    ///     `CMDocumentError.parsingError` if an invalid event type is encountered.
    /// - Returns:
    ///     The initialized parser.
    public init(text: String, startingFootnoteIndex: Int = 0, options: CMDocumentOption = [.sourcepos, .strikethroughDoubleTilde, .footnotes], extensions: CMExtensionOption = [.all], syntaxExtensions: [MarkdownExtension]) async throws {
        self.text = text
        self.footnoteIndex = startingFootnoteIndex
        self.lineOffsets = text.lineOffsets
        self.document = try CMDocument(text: text, options: options, extensions: extensions)
        self.syntax = SyntaxRegistry(syntaxExtensions)
    }

    // MARK: Internal parsing

    /// Builds the tree, and with syntax extensions keeps it.
    func buildTree() -> (root: Root, html: [ExtensionHTML.Request]) {
        if let built { return built }
        let builder = TreeBuilder(text: text, lineOffsets: lineOffsets, footnoteIndex: footnoteIndex, syntax: syntax)
        let root = Root(
            children: builder.content(from: document.node.view.firstChild),
            position: builder.position(for: document.node.view)
        )
        footnoteIndex = builder.footnoteIndex
        let result = (root: root, html: builder.htmlRequests)
        if !syntax.isEmpty { built = result }
        return result
    }
}

/// Builds the Swift tree from cmark's, in one walk, offering each anchor to its extensions.
///
/// One builder serves one build, inside the parser's isolation.
final class TreeBuilder {

    let text: String
    let lineOffsets: [String.Index]
    private(set) var footnoteIndex: Int
    let syntax: SyntaxRegistry

    /// The HTML recognized anchors asked for, one request per anchor, in the order recognized.
    private(set) var htmlRequests: [ExtensionHTML.Request] = []
    private var htmlAnchors = Set<UnsafeMutablePointer<cmark_node>>()

    init(text: String, lineOffsets: [String.Index], footnoteIndex: Int, syntax: SyntaxRegistry) {
        self.text = text
        self.lineOffsets = lineOffsets
        self.footnoteIndex = footnoteIndex
        self.syntax = syntax
    }

    // MARK: Walks

    func content(from first: CMNodeView?) -> [Content] {
        var items = [Content]()
        var cursor = first

        while let node = cursor {
            cursor = node.next

            if node.type == .footnoteDefinition {
                footnoteIndex += 1
                let value = "\(footnoteIndex)"
                let children = blocks(from: node.firstChild)
                items.append(FootnoteDefinition(identifier: value, label: value, children: children, position: position(for: node)))
                continue
            }

            if let extensions = syntax.extensions(for: node) {
                switch recognizeBlock(node, with: extensions) {
                case let .matched(nodes, resume):
                    items.append(contentsOf: nodes as [Content])
                    cursor = resume
                case let .unmatched(item):
                    if let item { items.append(item) }
                }
                continue
            }

            if let item = plainBlock(node) { items.append(item) }
        }
        return items
    }

    func blocks(from first: CMNodeView?) -> [BlockContent] {
        var items = [BlockContent]()
        var cursor = first

        while let node = cursor {
            cursor = node.next

            if let extensions = syntax.extensions(for: node) {
                switch recognizeBlock(node, with: extensions) {
                case let .matched(nodes, resume):
                    items.append(contentsOf: nodes)
                    cursor = resume
                case let .unmatched(item):
                    if let item { items.append(item) }
                }
                continue
            }

            if let item = plainBlock(node) { items.append(item) }
        }
        return items
    }

    func phrasing(from first: CMNodeView?) -> [PhrasingContent] {
        var items = [PhrasingContent]()
        var cursor = first

        while let node = cursor {
            cursor = node.next

            if let extensions = syntax.extensions(for: node) {
                switch recognizePhrasing(node, with: extensions) {
                case let .matched(nodes, resume):
                    items.append(contentsOf: nodes)
                    cursor = resume
                case let .unmatched(item):
                    if let item { items.append(item) }
                }
                continue
            }

            if let item = plainPhrasing(node) { items.append(item) }
        }
        return items
    }

    func tableContent(of table: CMNodeView) -> [TableContent] {
        var items = [TableContent]()

        for node in table.children {
            switch node.type {
            case .extension(.tableRow):
                let isHeader = node.humanReadableType == CMExtensionName.tableHeader.rawValue
                let children = rowContent(of: node)
                items.append(TableRow(isHeader: isHeader, children: children, position: position(for: node)))

            default: break
            }
        }
        return items
    }

    func rowContent(of row: CMNodeView) -> [RowContent] {
        var items = [RowContent]()

        for node in row.children where node.type == .extension(.tableCell) {
            let children = phrasing(from: node.firstChild)
            items.append(TableCell(children: children, position: position(for: node)))
        }
        return items
    }

    func listContent(of list: CMNodeView, spread: Bool?) -> [ListContent] {
        var items = [ListContent]()

        for node in list.children where node.type == .item {
            let children = blocks(from: node.firstChild)
            items.append(ListItem(checked: node.taskCompleted, spread: spread, children: children, position: position(for: node)))
        }
        return items
    }

    // MARK: Nodes as cmark reads them

    /// A block node as the tree holds it with no extension recognizing it; `nil` for one it
    /// leaves out.
    func plainBlock(_ node: CMNodeView) -> BlockContent? {
        switch node.type {
        case .heading:
            let children = phrasing(from: node.firstChild)
            let depth = Heading.Depth(rawValue: Int(node.headingLevel)) ?? .h6
            return Heading(children: children, depth: depth, position: position(for: node))

        case .paragraph:
            return Paragraph(children: phrasing(from: node.firstChild), position: position(for: node))

        case .blockQuote:
            return Blockquote(children: blocks(from: node.firstChild), position: position(for: node))

        case .thematicBreak:
            return ThematicBreak(position: position(for: node))

        case .codeBlock:
            guard let value = node.literal else { return nil }
            let language = node.fencedCodeInfo
            return Code(value: value, language: language, meta: nil, position: position(for: node))

        case .htmlBlock:
            guard let value = node.literal else { return nil }
            return HTML(value: value, position: position(for: node))

        case .list:
            let ordered = node.listType == .ordered
            let listStartingNumber = Int(node.listStartingNumber)
            let start: Int? = listStartingNumber > 0 ? listStartingNumber : nil
            let spread = !node.listTight
            let children = listContent(of: node, spread: spread)
            return List(ordered: ordered, start: start, spread: spread, children: children, position: position(for: node))

        case .extension(.table):
            let align = node.getTableAlignments()
            let children = tableContent(of: node)
            return Table(align: align, children: children, position: position(for: node))

        default:
            return nil
        }
    }

    /// A phrasing node as the tree holds it with no extension recognizing it; `nil` for one it
    /// leaves out.
    func plainPhrasing(_ node: CMNodeView) -> PhrasingContent? {
        switch node.type {
        case .text:
            guard let value = node.literal else { return nil }
            return Text(value: value, position: position(for: node))

        case .emphasis:
            return Emphasis(children: phrasing(from: node.firstChild), position: position(for: node))

        case .strong:
            return Strong(children: phrasing(from: node.firstChild), position: position(for: node))

        case .code:
            guard let value = node.literal else { return nil }
            return InlineCode(value: value, position: position(for: node))

        case .extension(.strikethrough):
            return Delete(children: phrasing(from: node.firstChild), position: position(for: node))

        case .softBreak:
            return SoftBreak(position: position(for: node))

        case .lineBreak:
            return Break(position: position(for: node))

        case .link:
            guard let url = node.linkUrl, let title = node.linkTitle else { return nil }
            let label = phrasing(from: node.firstChild)
            guard let children = (label as? [StaticPhrasingContent]) ?? staticFallback(label) else { return nil }
            let kind = node.linkSyntax(in: text, using: lineOffsets).kind
            // An autolink is its own label, so it has none of its own.
            let labelPosition = kind == .autolink ? nil : labelPosition(from: children.first?.position, to: children.last?.position)
            return Link(url: url, title: title, kind: kind, children: children, position: position(for: node), labelPosition: labelPosition)

        case .image:
            guard let url = node.linkUrl, let title = node.linkTitle else { return nil }
            let children = phrasing(from: node.firstChild)
            let alt = node.getAll(where: { $0.type == .text }).compactMap({$0.literal}).joined(separator: "")
            let label = labelPosition(from: children.first?.position, to: children.last?.position)
            return Image(url: url, title: title, alt: alt, children: children, position: position(for: node), labelPosition: label)

        case .footnoteReference:
            guard let value = node.literal else { return nil }
            return FootnoteReference(identifier: value, label: value, position: position(for: node))

        case .htmlInline:
            guard let value = node.literal else { return nil }
            return HTML(value: value, position: position(for: node))

        default:
            return nil
        }
    }

    /// A link label holding an extension's node that isn't static phrasing content, read with
    /// each such node as its `plain`, since a link's children are static. `nil` without
    /// extensions, or when that still isn't static.
    private func staticFallback(_ label: [PhrasingContent]) -> [StaticPhrasingContent]? {
        guard !syntax.isEmpty else { return nil }
        var children = [StaticPhrasingContent]()
        for node in label {
            if let node = node as? StaticPhrasingContent {
                children.append(node)
            } else if let node = node as? ExtensionContent, let plain = node.plain as? [StaticPhrasingContent] {
                children.append(contentsOf: plain)
            } else {
                return nil
            }
        }
        return children
    }

    // MARK: Recognition

    enum Recognition<Element> {
        /// An extension's nodes, and the node after the last one they stand for.
        case matched([Element], resume: CMNodeView?)
        /// No extension recognized the node: its own reading.
        case unmatched(Element?)
    }

    private func recognizeBlock(_ node: CMNodeView, with extensions: [MarkdownExtension]) -> Recognition<BlockContent> {
        var context = ParseContext(builder: self, anchor: node, isBlock: true)
        for syntax in extensions {
            if let nodes = syntax.recognizeBlock(in: &context) {
                commit(context.html)
                return .matched(nodes, resume: context.resume)
            }
            context.reset()
        }
        return .unmatched(context.cachedBlock ?? plainBlock(node))
    }

    private func recognizePhrasing(_ node: CMNodeView, with extensions: [MarkdownExtension]) -> Recognition<PhrasingContent> {
        var context = ParseContext(builder: self, anchor: node, isBlock: false)
        for syntax in extensions {
            if let nodes = syntax.recognizePhrasing(in: &context) {
                commit(context.html)
                return .matched(nodes, resume: context.resume)
            }
            context.reset()
        }
        return .unmatched(context.cachedPhrasing ?? plainPhrasing(node))
    }

    /// Keeps one HTML request per anchor: a subtree read twice asks twice.
    private func commit(_ request: ExtensionHTML.Request?) {
        guard let request, htmlAnchors.insert(request.anchor).inserted else { return }
        htmlRequests.append(request)
    }

    /// Whether a custom node can take this node's place in its parent.
    func canWrap(_ node: CMNodeView, inBlock isBlock: Bool) -> Bool {
        guard let parent = node.parent else { return false }
        return cmark_node_can_contain_type(parent.pointer, isBlock ? CMARK_NODE_CUSTOM_BLOCK : CMARK_NODE_CUSTOM_INLINE)
    }

    /// The source a run of adjacent text nodes covers, when each one's literal is its source.
    func literalTextRun(_ nodes: [CMNodeView]) -> Range<String.Index>? {
        var run: Range<String.Index>?
        for node in nodes {
            guard
                node.type == .text,
                let range = range(of: node),
                let literal = node.literal,
                literal[...] == text[range]
            else { return nil }
            if let current = run {
                guard current.upperBound == range.lowerBound else { return nil }
                run = current.lowerBound..<range.upperBound
            } else {
                run = range
            }
        }
        return run
    }

    // MARK: Position

    func position(for node: CMNodeView) -> Position {
        switch node.type {
        case .link, .footnoteDefinition, .text:
            return node.adjustedPosition(in: text, using: lineOffsets)
        default:
            return node.position(in: text, using: lineOffsets)
        }
    }

    /// Position spanning a node's children — the label between a link's or image's brackets.
    ///
    /// `nil` when there are no children, e.g. `[](url)`.
    func labelPosition(from first: Position?, to last: Position?) -> Position? {
        guard let first, let last else { return nil }
        return Position(start: first.start, end: last.end, indent: nil)
    }

    /// The source range of a node's position: its first character up to the one after its last.
    func range(of node: CMNodeView) -> Range<String.Index>? {
        let position = position(for: node)
        guard let start = position.start.offset, let end = position.end.offset, end < text.endIndex else { return nil }
        return start..<text.utf8.index(after: end)
    }

    /// The position of a source range, as the nodes have theirs: the line, the 1-based UTF-8
    /// column and the offset of its first character and of its last byte.
    func position(of range: Range<String.Index>) -> Position? {
        guard
            !range.isEmpty,
            range.lowerBound >= text.startIndex,
            range.upperBound <= text.endIndex
        else { return nil }
        let last = text.utf8.index(before: range.upperBound)
        return Position(start: point(at: range.lowerBound), end: point(at: last), indent: nil)
    }

    private func point(at index: String.Index) -> Point {
        // The last line that starts at or before `index`.
        var low = 0, high = lineOffsets.count - 1
        while low < high {
            let middle = (low + high + 1) / 2
            if lineOffsets[middle] <= index { low = middle } else { high = middle - 1 }
        }
        let column = text.utf8.distance(from: lineOffsets[low], to: index) + 1
        return Point(line: low + 1, column: column, offset: index)
    }
}
