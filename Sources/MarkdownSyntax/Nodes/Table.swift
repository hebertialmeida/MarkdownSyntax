//
//  Table.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct Table: BlockContent, Parent {
    public let align: [AlignType]?
    public let children: [TableContent]
    public let position: Position

    public init(align: [AlignType]?, children: [TableContent], position: Position) {
        self.align = align
        self.children = children
        self.position = position
    }
}
