//
//  TableRow.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct TableRow: TableContent, Parent {
    public let type: NodeType = .tableRow
    public let isHeader: Bool
    public let children: [RowContent]
    public let position: Position

    public init(isHeader: Bool, children: [RowContent], position: Position) {
        self.isHeader = isHeader
        self.children = children
        self.position = position
    }
}
