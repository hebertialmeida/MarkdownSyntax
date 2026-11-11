//
//  NodeKind.swift
//  MarkdownSyntax
//

/// The kind of node a ``SourceNode`` is, named after the tree's node types.
///
/// An extension names the kinds it starts from in its ``MarkdownExtension/anchors``. A
/// ``SourceNode`` reads its kind from ``SourceNode/kind``. Each case is the node the tree builds
/// for it: `.code` is a ``Code`` block and `.inlineCode` an ``InlineCode`` span, `.html` an
/// ``HTML`` block and `.inlineHTML` an ``HTML`` span.
///
/// `.root`, `.listItem`, `.tableRow`, `.tableCell` and `.footnoteDefinition` are never offered as
/// anchors: the tree build reads them as the frame of what they contain. They are kinds a
/// ``SourceNode/parent`` can have.
public enum NodeKind: Hashable, Sendable, CaseIterable {

    // MARK: Block

    /// The document, read as ``Root``.
    case root
    /// A ``Blockquote``.
    case blockquote
    /// A ``List``.
    case list
    /// A ``ListItem``.
    case listItem
    /// A fenced or indented ``Code`` block.
    case code
    /// An ``HTML`` block.
    case html
    /// A ``Paragraph``.
    case paragraph
    /// A ``Heading``.
    case heading
    /// A ``ThematicBreak``.
    case thematicBreak
    /// A ``FootnoteDefinition``.
    case footnoteDefinition
    /// A ``Table``.
    case table
    /// A ``TableRow``.
    case tableRow
    /// A ``TableCell``.
    case tableCell

    // MARK: Phrasing

    /// A run of ``Text``.
    case text
    /// A ``SoftBreak``, a line ending inside a paragraph.
    case softBreak
    /// A hard ``Break``.
    case lineBreak
    /// An ``InlineCode`` span.
    case inlineCode
    /// Inline ``HTML``.
    case inlineHTML
    /// ``Emphasis``.
    case emphasis
    /// ``Strong`` emphasis.
    case strong
    /// Struck-through text, a ``Delete``.
    case delete
    /// A ``Link``.
    case link
    /// An ``Image``.
    case image
    /// A ``FootnoteReference``.
    case footnoteReference
}

extension NodeKind {

    /// The cmark node type the tree reads as this kind.
    var cmarkType: CMNodeType {
        switch self {
        case .root: .document
        case .blockquote: .blockQuote
        case .list: .list
        case .listItem: .item
        case .code: .codeBlock
        case .html: .htmlBlock
        case .paragraph: .paragraph
        case .heading: .heading
        case .thematicBreak: .thematicBreak
        case .footnoteDefinition: .footnoteDefinition
        case .table: .extension(.table)
        case .tableRow: .extension(.tableRow)
        case .tableCell: .extension(.tableCell)
        case .text: .text
        case .softBreak: .softBreak
        case .lineBreak: .lineBreak
        case .inlineCode: .code
        case .inlineHTML: .htmlInline
        case .emphasis: .emphasis
        case .strong: .strong
        case .delete: .extension(.strikethrough)
        case .link: .link
        case .image: .image
        case .footnoteReference: .footnoteReference
        }
    }

    /// The kind of a cmark node type, or `nil` for one the tree has no node for (a custom block
    /// or inline, or a cmark extension's node it doesn't read).
    init?(_ type: CMNodeType) {
        switch type {
        case .document: self = .root
        case .blockQuote: self = .blockquote
        case .list: self = .list
        case .item: self = .listItem
        case .codeBlock: self = .code
        case .htmlBlock: self = .html
        case .paragraph: self = .paragraph
        case .heading: self = .heading
        case .thematicBreak: self = .thematicBreak
        case .footnoteDefinition: self = .footnoteDefinition
        case .extension(.table): self = .table
        case .extension(.tableRow): self = .tableRow
        case .extension(.tableCell): self = .tableCell
        case .text: self = .text
        case .softBreak: self = .softBreak
        case .lineBreak: self = .lineBreak
        case .code: self = .inlineCode
        case .htmlInline: self = .inlineHTML
        case .emphasis: self = .emphasis
        case .strong: self = .strong
        case .extension(.strikethrough): self = .delete
        case .link: self = .link
        case .image: self = .image
        case .footnoteReference: self = .footnoteReference
        case .none, .customBlock, .customInline, .extension(.other): return nil
        }
    }
}
