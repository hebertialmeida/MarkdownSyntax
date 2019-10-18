//
//  List.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

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
