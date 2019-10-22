//
//  Position.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// Location of a node in a source file.
public struct Position: Equatable {
    /// Place of the first character of the parsed source region.
    public let start: Point

    /// Place of the first character after the parsed source region.
    public let end: Point

    /// Start column at each index (plus start line) in the source region,
    /// for elements that span multiple lines.
    public let indent: [Int]?

    public init(start: Point, end: Point, indent: [Int]?) {
        self.start = start
        self.end = end
        self.indent = indent
    }
}
