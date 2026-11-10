//
//  MarkdownExtension.swift
//  MarkdownSyntax
//

/// A syntax extension: syntax of your own, recognized while the tree is built.
///
/// cmark parses the source as CommonMark and GitHub Flavored Markdown. An extension adds
/// syntax on top of that grammar by reading what cmark made of the source: it names the node
/// types it starts from, its ``anchors``, and the tree build offers it every node of those
/// types, in the one walk that builds the tree. When it recognizes its syntax, it returns its
/// own nodes in place of the anchor's; otherwise it returns `nil` and the anchor reads as
/// cmark's node.
///
/// ```swift
/// let markdown = try await Markdown(text: source, syntaxExtensions: [HighlightExtension()])
/// let tree = await markdown.parse()
/// ```
///
/// Implement ``recognizeBlock(in:)`` for an anchor that is block content (a paragraph, a block
/// quote, a code block, a table, a heading…) and ``recognizePhrasing(in:)`` for one that is
/// phrasing content (text, an image, a link…). The nodes you return usually conform to
/// ``ExtensionContent``, so a reader of the tree that doesn't know them can fall back to cmark's
/// reading of the same source.
///
/// When several extensions share an anchor type, they are tried in the order they were given to
/// ``Markdown/init(text:startingFootnoteIndex:options:extensions:syntaxExtensions:)``, and the
/// first that recognizes the node wins. A node whose type no extension names costs one lookup.
///
/// See <doc:ExtendingTheSyntax>.
public protocol MarkdownExtension: Sendable {

    /// The cmark node types this extension starts from.
    ///
    /// Only nodes of these types are offered to the recognizers. Name the narrowest type your
    /// syntax can start in: `.blockQuote` for a syntax written on a quote, `.text` for one
    /// written in running text. See <doc:Anchors>.
    var anchors: [CMNodeType] { get }

    /// Recognizes the syntax at an anchor met as block content.
    ///
    /// - Parameter context: The anchor, its source, and the tools to read it, claim the siblings
    ///   that follow it and give it HTML.
    /// - Returns: The nodes that replace the anchor (and every sibling claimed), in order, or
    ///   `nil` when the anchor isn't this extension's syntax. Returning `nil` discards the
    ///   claims and HTML asked for in this call.
    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]?

    /// Recognizes the syntax at an anchor met as phrasing content.
    ///
    /// - Parameter context: The anchor, its source, and the tools to read it, claim the siblings
    ///   that follow it and give it HTML.
    /// - Returns: The nodes that replace the anchor (and every sibling claimed), in order, or
    ///   `nil` when the anchor isn't this extension's syntax. Returning `nil` discards the
    ///   claims and HTML asked for in this call.
    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]?
}

public extension MarkdownExtension {

    /// Recognizes nothing: an extension with no block syntax needn't implement this.
    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]? {
        nil
    }

    /// Recognizes nothing: an extension with no phrasing syntax needn't implement this.
    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        nil
    }
}

/// The registered extensions, indexed by the raw cmark type of their anchors.
struct SyntaxRegistry: Sendable {

    /// The extensions for each anchor type, in registration order.
    private let table: [UInt32: [MarkdownExtension]]

    init(_ extensions: [MarkdownExtension]) {
        var table: [UInt32: [MarkdownExtension]] = [:]
        for syntax in extensions {
            // A type named twice by one extension is offered to it once.
            var seen = Set<UInt32>()
            for anchor in syntax.anchors where seen.insert(anchor.rawValue).inserted {
                table[anchor.rawValue, default: []].append(syntax)
            }
        }
        self.table = table
    }

    /// No extension is registered, so the tree is built exactly as without extensions.
    var isEmpty: Bool {
        table.isEmpty
    }

    /// The extensions anchored on this node's type, or `nil` when there are none.
    @inline(__always)
    func extensions(for node: CMNodeView) -> [MarkdownExtension]? {
        table.isEmpty ? nil : table[node.rawType]
    }
}
