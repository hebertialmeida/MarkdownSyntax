//
//  ThematicBreak.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// A thematic break: `---`, `***` or `___` on a line of its own.
public struct ThematicBreak: BlockContent {
    public let position: Position

    public init(position: Position) {
        self.position = position
    }
}
