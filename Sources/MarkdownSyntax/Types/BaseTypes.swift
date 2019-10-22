//
//  BaseTypes.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-07.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

import struct Foundation.URL

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
