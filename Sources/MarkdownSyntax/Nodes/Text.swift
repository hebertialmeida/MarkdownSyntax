//
//  Text.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// A run of text, its entities and escapes resolved in `value`.
public struct Text: StaticPhrasingContent, PhrasingContent, Literal {
    public let value: String
    public let position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}
