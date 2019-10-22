//
//  LineBreak.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// LineBreak represents a hard line break, such as new paragraph.
public struct LineBreak: StaticPhrasingContent, PhrasingContent {
    public let type: NodeType = .lineBreak
    public let position: Position

    public init(position: Position) {
        self.position = position
    }
}
