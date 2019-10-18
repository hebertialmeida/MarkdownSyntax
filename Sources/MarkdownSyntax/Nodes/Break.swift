//
//  Break.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct Break: StaticPhrasingContent, PhrasingContent {
    public let type: NodeType = .break
    public let position: Position

    public init(position: Position) {
        self.position = position
    }
}
