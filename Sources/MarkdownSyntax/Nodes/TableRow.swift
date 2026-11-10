//
//  TableRow.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// One row of a GFM table; the first is the header row.
public struct TableRow: TableContent, Parent {
    public let isHeader: Bool
    public let children: [RowContent]
    public let position: Position

    public init(isHeader: Bool, children: [RowContent], position: Position) {
        self.isHeader = isHeader
        self.children = children
        self.position = position
    }
}
