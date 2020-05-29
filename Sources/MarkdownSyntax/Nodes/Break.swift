//
//  Break.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// Break represents a soft line break, such as in poems or addresses.
public struct Break: StaticPhrasingContent, PhrasingContent {
    public let position: Position

    public init(position: Position) {
        self.position = position
    }
}
