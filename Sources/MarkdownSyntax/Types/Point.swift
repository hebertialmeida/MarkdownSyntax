//
//  Point.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// One place in a source file.
public struct Point: Equatable {
    /// Line in a source file (1-indexed integer).
    public var line: Int

    /// Column in a source file (1-indexed integer).
    public var column: Int

    /// Character in a source file (0-indexed integer).
    public var offset: Int?

    public init(line: Int, column: Int, offset: Int?) {
        self.line = line
        self.column = column
        self.offset = offset
    }
}
