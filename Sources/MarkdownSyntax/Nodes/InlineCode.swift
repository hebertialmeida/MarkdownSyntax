//
//  InlineCode.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct InlineCode: StaticPhrasingContent, PhrasingContent, Literal {
    public let type: NodeType = .inlineCode
    public let value: String
    public let position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}
