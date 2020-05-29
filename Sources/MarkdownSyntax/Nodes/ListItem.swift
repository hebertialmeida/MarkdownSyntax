//
//  ListItem.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct ListItem: ListContent, Parent {
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
