//
//  CMNode+Position.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-17.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

extension CMNode {

    var position: Position {
        return Position(
            start: Point(line: Int(startLine), column: Int(startColumn), offset: nil),
            end: Point(line: Int(endLine), column: Int(endColumn), offset: nil),
            indent: nil
        )
    }

    /// When visiting a node, you can modify the state, and the modified state gets passed on to all children.
    func visitAll(_ callback: (CMNode) -> ()) {
        for c in children {
            callback(c)
            c.visitAll(callback)
        }
    }

    func getAll(where predicate: (CMNode) -> Bool) -> [CMNode] {
        var nodes: [CMNode] = []

        for c in children {
            if predicate(c) {
                nodes.append(c)
            }
            nodes.append(contentsOf: c.getAll(where: predicate))
        }

        return nodes
    }
}
