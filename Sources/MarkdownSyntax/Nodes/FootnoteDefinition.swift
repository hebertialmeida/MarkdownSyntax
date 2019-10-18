//
//  FootnoteDefinition.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

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
