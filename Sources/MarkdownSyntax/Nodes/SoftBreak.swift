//
//  SoftBreak.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// SoftBreak represents a hard line break, such as new paragraph.
public struct SoftBreak: StaticPhrasingContent, PhrasingContent {
    public let type: NodeType = .softBreak
    public let position: Position

    public init(position: Position) {
        self.position = position
    }
}
