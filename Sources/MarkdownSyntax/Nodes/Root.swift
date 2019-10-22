//
//  Root.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

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
