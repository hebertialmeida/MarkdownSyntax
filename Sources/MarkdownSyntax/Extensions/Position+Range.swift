//
//  Position+Range.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public extension Position {

    /// Range of node if `start` and `end` points can form a valid range
    var range: ClosedRange<String.Index>? {
        guard let start = start.offset, let end = end.offset else { return nil }
        return start...end
    }
}
