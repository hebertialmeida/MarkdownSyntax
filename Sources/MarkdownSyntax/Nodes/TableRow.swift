//
//  TableRow.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct TableRow: TableContent, Parent {
    public let type: NodeType = .tableRow
    public let children: [RowContent]
    public let position: Position

    public init(children: [RowContent], position: Position) {
        self.children = children
        self.position = position
    }
}
