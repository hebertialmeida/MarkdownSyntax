//
//  HTML.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct HTML: BlockContent, StaticPhrasingContent, PhrasingContent, Literal {
    public var type: NodeType = .html
    public var value: String
    public var position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}
