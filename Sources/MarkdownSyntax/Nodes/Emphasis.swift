//
//  Emphasis.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// Emphasis: `*text*` or `_text_`.
public struct Emphasis: StaticPhrasingContent, PhrasingContent, Parent {
    public let children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}
