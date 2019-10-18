//
//  File.swift
//  
//
//  Created by Heberti Almeida on 2019-10-07.
//

import Foundation

public enum NodeType: String, Codable {
    case root
    case paragraph
    case heading
    case thematicBreak
    case blockquote
    case list
    case listItem
    case table
    case tableRow
    case tableCell
    case html
    case code
    case yaml
    case definition //
    case footnoteDefinition
    case text
    case emphasis
    case strong
    case delete
    case inlineCode
    case `break`
    case link
    case image
    case linkReference
    case imageReference
    case footnote
    case footnoteReference
}

/// Location of a node in a source file.
public struct Position: Equatable {
    /// Place of the first character of the parsed source region.
    public let start: Point

    /// Place of the first character after the parsed source region.
    public let end: Point

    /// Start column at each index (plus start line) in the source region,
    /// for elements that span multiple lines.
    public let indent: [Int]?

    public init(start: Point, end: Point, indent: [Int]?) {
        self.start = start
        self.end = end
        self.indent = indent
    }
}

/// One place in a source file.
public struct Point: Equatable {
    /// Line in a source file (1-indexed integer).
    public var line: Int

    /// Column in a source file (1-indexed integer).
    public var column: Int

    /// Character in a source file (0-indexed integer).
    public var offset: Int?

    public init(line: Int, column: Int, offset: Int?) {
        self.line = line
        self.column = column
        self.offset = offset
    }
}

// MARK: Base Types

/// Syntactic units in unist syntax trees are called nodes.
public protocol Node {
    /// The variant of a node.
    var type: NodeType { get }

    /// Location of a node in a source document.
    /// Must not be present if a node is generated.
    var position: Position { get }
}

/// Nodes containing other nodes.
public protocol Parent: Node {
    associatedtype Element

    /// List representing the children of a node.
    var children: [Element] { get }
}

/// Nodes containing a value.
public protocol Literal: Node {
    var value: String { get }
}

// MARK: - Mixin

public protocol Resource {
    var url: URL { get }
    var title: String? { get }
}

public protocol Association {
    var identifier: String { get }
    var label: String? { get }
}

public protocol Reference {
    var referenceType: ReferenceType { get }
}

public protocol Alternative {
    var alt: String? { get }
}

// MARK: -  MD Types

public enum AlignType: String, Codable {
    case left
    case right
    case center
    case none
}

public enum ReferenceType: String, Codable {
    case shortcut
    case collapsed
    case full
}

//MARK: - Protocols

/// Each node in mdast falls into one or more categories of Content that group nodes with similar characteristics together.
public protocol Content: Node {}

/// Block content represent the sections of document.
public protocol BlockContent: Content {}

/// List content represent the items in a list.
public protocol ListContent: Content {}

/// Row content represent the cells in a row.
public protocol RowContent: Content {}

/// Table content represent the rows in a table.
public protocol TableContent: Content {}

/// Phrasing content represent the text in a document, and its markup.
public protocol PhrasingContent: Content {}

/// StaticPhrasing content represent the text in a document, and its markup, that is not intended for user interaction.
public protocol StaticPhrasingContent: PhrasingContent {}

/// Frontmatter content represent out-of-band information about the document.
/// If frontmatter is present, it must be limited to one node in the tree, and can only exist as a head.
public protocol FrontmatterContent: Content {}

/// Definition content represents out-of-band information that typically affects the document through Association.
public protocol DefinitionContent: Content {}

/// Top-level content represent the sections of document (block content), and metadata such as frontmatter and definitions.
public protocol TopLevelContent: BlockContent, FrontmatterContent, DefinitionContent {}

// MARK: - Root

/// # Root (Parent) represents a document.
/// Root can be used as the root of a tree, never as a child. Its content model is not limited to top-level content,
/// but can contain any content with the restriction that all content must be of the same category.
public struct Root: Parent {
    public let type: NodeType = .root
    public let children: [Content]
    public let position: Position

    public init(children: [Content], position: Position) {
        self.children = children
        self.position = position
    }
}

// MARK: - BlockContent

public struct Heading: BlockContent, Parent {
    public let type: NodeType = .heading
    public let children: [PhrasingContent]
    public let depth: Depth
    public let position: Position

    public init(children: [PhrasingContent], depth: Depth, position: Position) {
        self.children = children
        self.depth = depth
        self.position = position
    }
}

public extension Heading {
    enum Depth: Int, Codable {
        case h1 = 1
        case h2 = 2
        case h3 = 3
        case h4 = 4
        case h5 = 5
        case h6 = 6
    }
}

public struct Paragraph: BlockContent, Parent {
    public let type: NodeType = .paragraph
    public let children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}

public struct Blockquote: BlockContent, Parent {
    public let type: NodeType = .blockquote
    public let children: [BlockContent]
    public let position: Position

    public init(children: [BlockContent], position: Position) {
        self.children = children
        self.position = position
    }
}

public struct ThematicBreak: BlockContent {
    public let type: NodeType = .thematicBreak
    public let position: Position

    public init(position: Position) {
        self.position = position
    }
}

public struct Code: BlockContent, Literal {
    public let type: NodeType = .code
    public let value: String
    public let language: String?
    public let meta: String?
    public let position: Position

    public init(value: String, language: String?, meta: String?, position: Position) {
        self.value = value
        self.language = language
        self.meta = meta
        self.position = position
    }
}

public struct HTML: BlockContent, StaticPhrasingContent, PhrasingContent, Literal {
    public var type: NodeType = .html
    public var value: String
    public var position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}

public struct List: BlockContent, Parent {
    public let type: NodeType = .list
    public let ordered: Bool
    public let start: Int?
    public let spread: Bool?
    public let children: [ListContent]
    public let position: Position

    public init(ordered: Bool, start: Int?, spread: Bool?, children: [ListContent], position: Position) {
        self.ordered = ordered
        self.start = start
        self.spread = spread
        self.children = children
        self.position = position
    }
}

public struct ListItem: ListContent, Parent {
    public let type: NodeType = .listItem
    public let checked: Bool?
    public let spread: Bool?
    public let children: [BlockContent]
    public let position: Position

    public init(checked: Bool?, spread: Bool?, children: [BlockContent], position: Position) {
        self.checked = checked
        self.spread = spread
        self.children = children
        self.position = position
    }
}

public struct Table: BlockContent, Parent {
    public let type: NodeType = .table
    public let align: [AlignType]?
    public let children: [TableContent]
    public let position: Position

    public init(align: [AlignType]?, children: [TableContent], position: Position) {
        self.align = align
        self.children = children
        self.position = position
    }
}

// MARK: FrontmatterContent

public struct YAML: FrontmatterContent, Literal {
    public var type: NodeType = .yaml
    public var value: String
    public var position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}

// MARK: - PhrasingContent

public struct Link: PhrasingContent, Parent, Resource {
    public let type: NodeType = .link
    public let url: URL
    public let title: String?
    public let children: [StaticPhrasingContent]
    public let position: Position

    public init(url: URL, title: String?, children: [StaticPhrasingContent], position: Position) {
        self.url = url
        self.title = title
        self.children = children
        self.position = position
    }
}

public struct LinkReference: PhrasingContent, Parent, Reference {
    public let type: NodeType = .linkReference
    public let referenceType: ReferenceType
    public let children: [StaticPhrasingContent]
    public let position: Position

    public init(referenceType: ReferenceType, children: [StaticPhrasingContent], position: Position) {
        self.referenceType = referenceType
        self.children = children
        self.position = position
    }
}

// MARK: - StaticPhrasingContent

public struct Text: StaticPhrasingContent, PhrasingContent, Literal {
    public let type: NodeType = .text
    public let value: String
    public let position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}

public struct InlineCode: StaticPhrasingContent, PhrasingContent, Literal {
    public let type: NodeType = .inlineCode
    public let value: String
    public let position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}

public struct Emphasis: StaticPhrasingContent, PhrasingContent, Parent {
    public let type: NodeType = .emphasis
    public var children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}

public struct Strong: StaticPhrasingContent, PhrasingContent, Parent {
    public let type: NodeType = .strong
    public var children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}

public struct Delete: StaticPhrasingContent, PhrasingContent, Parent {
    public let type: NodeType = .delete
    public var children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}

public struct Break: StaticPhrasingContent, PhrasingContent {
    public let type: NodeType = .break
    public let position: Position

    public init(position: Position) {
        self.position = position
    }
}

public struct Image: StaticPhrasingContent, PhrasingContent, Parent, Resource, Alternative {
    public let type: NodeType = .image
    public let url: URL
    public let title: String?
    public let alt: String?
    public let children: [PhrasingContent]
    public let position: Position

    public init(url: URL, title: String?, alt: String?, children: [PhrasingContent], position: Position) {
        self.url = url
        self.title = title
        self.alt = alt
        self.children = children
        self.position = position
    }
}

public struct ImageReference: StaticPhrasingContent, PhrasingContent, Parent, Reference, Alternative {
    public let type: NodeType = .imageReference
    public let referenceType: ReferenceType
    public let alt: String?
    public let children: [PhrasingContent]
    public let position: Position

    public init(referenceType: ReferenceType, alt: String?, children: [PhrasingContent], position: Position) {
        self.referenceType = referenceType
        self.alt = alt
        self.children = children
        self.position = position
    }
}

public struct Footnote: StaticPhrasingContent, PhrasingContent, Parent {
    public let type: NodeType = .footnote
    public let children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}

public struct FootnoteReference: StaticPhrasingContent, PhrasingContent, Association {
    public var type: NodeType = .footnoteReference
    public var identifier: String
    public var label: String?
    public var position: Position

    public init(identifier: String, label: String?, position: Position) {
        self.identifier = identifier
        self.label = label
        self.position = position
    }
}

// MARK: - DefinitionContent

public struct Definition: DefinitionContent, Association, Resource {
    public let type: NodeType = .definition
    public let identifier: String
    public let label: String?
    public let url: URL
    public let title: String?
    public let position: Position

    public init(identifier: String, label: String?, url: URL, title: String?, position: Position) {
        self.identifier = identifier
        self.label = label
        self.url = url
        self.title = title
        self.position = position
    }
}

public struct FootnoteDefinition: DefinitionContent, Parent, Association {
    public let type: NodeType = .footnoteDefinition
    public let identifier: String
    public let label: String?
    public let children: [BlockContent]
    public let position: Position

    public init(identifier: String, label: String?, children: [BlockContent], position: Position) {
        self.identifier = identifier
        self.label = label
        self.children = children
        self.position = position
    }
}

// MARK: Others

public struct TableRow: TableContent, Parent {
    public let type: NodeType = .tableRow
    public let children: [RowContent]
    public let position: Position

    public init(children: [RowContent], position: Position) {
        self.children = children
        self.position = position
    }
}

public struct TableCell: RowContent, Parent {
    public let type: NodeType = .tableRow
    public let children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}
