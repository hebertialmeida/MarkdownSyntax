//
//  YAML.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// YAML front matter.
public struct YAML: FrontmatterContent, Literal {
    public var value: String
    public var position: Position

    public init(value: String, position: Position) {
        self.value = value
        self.position = position
    }
}
