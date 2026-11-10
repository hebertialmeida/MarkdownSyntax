//
//  Blockquote.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// A block quote: lines written after `>`.
public struct Blockquote: BlockContent, Parent {
    public let children: [BlockContent]
    public let position: Position

    public init(children: [BlockContent], position: Position) {
        self.children = children
        self.position = position
    }
}
