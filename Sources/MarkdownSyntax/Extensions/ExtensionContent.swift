//
//  ExtensionContent.swift
//  MarkdownSyntax
//

/// A node a ``MarkdownExtension`` made, which knows how cmark alone reads its source.
///
/// Conform your extension's node types to this protocol, and to ``BlockContent`` or
/// ``PhrasingContent`` for where they appear. A reader of the tree then handles the nodes it
/// knows and falls back to ``plain`` for the rest, so a new extension never breaks a reader
/// written before it:
///
/// ```swift
/// switch node {
/// case let highlight as Highlight:
///     renderHighlight(highlight)
/// case let other as ExtensionContent:
///     render(other.plain)          // what the tree held without the extension
/// case let paragraph as Paragraph:
///     …
/// }
/// ```
///
/// Ranges inside the node are its own stored properties, named for what they cover
/// (`markerPosition`, `targetPosition`…), and ``subpositions`` lists them by name for readers
/// that handle any extension alike. See <doc:Ranges> and <doc:PlainFallback>.
public protocol ExtensionContent: Content {

    /// The nodes the same source reads as without this extension, in order.
    ///
    /// For an extension that replaces a whole cmark node, this is that node as the tree would
    /// hold it, and the siblings it claimed after it. For one that recognizes part of a text
    /// node, it is a ``Text`` over the part recognized. Extensions nested inside stay
    /// recognized: a reader that falls back to `plain` meets them as nodes of their own.
    var plain: [Content] { get }

    /// The named ranges inside ``Node/position``, such as a marker or a target.
    ///
    /// Each name is the node's own property name for that range. The default is empty.
    var subpositions: [String: Position] { get }
}

public extension ExtensionContent {

    /// No named ranges.
    var subpositions: [String: Position] {
        [:]
    }
}
