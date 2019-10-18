//
//  Code.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

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
