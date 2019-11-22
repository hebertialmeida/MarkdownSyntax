//
//  CMNode+Position.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-17.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

extension CMNode {

    func position(in text: String, using lineOffsets: [String.Index]) -> Position {
        let startLine = Int(self.startLine)
        let startColumn = Int(self.startColumn)
        let endLine = Int(self.endLine)
        let endColumn = Int(self.endColumn)

        var startPoint = Point(line: startLine, column: startColumn, offset: nil)
        var endPoint = Point(line: endLine, column: endColumn, offset: nil)

        func index(of point: Point) -> String.Index {
            let line = point.line > 0 ? point.line-1 : point.line
            let lineStart = lineOffsets[line]
            let offset = point.column > 0 ? point.column-1 : point.column
            // We don't use endIndex but the index before, because we use it in a closed range
            let lastValidIndex = text.index(before: text.endIndex)
            return text.utf8.index(lineStart, offsetBy: offset, limitedBy: lastValidIndex) ?? lastValidIndex
        }

        func failEarly() -> Position {
            return Position(start: startPoint, end: endPoint, indent: nil)
        }

        guard
            startColumn > 0 && startLine > 0,
            text.startIndex != text.endIndex
        else {
            return failEarly()
        }

        let start = index(of: startPoint)
        let end = index(of: endPoint)

        guard
            start <= end,
            start >= text.startIndex,
            end < text.endIndex
        else {
            return failEarly()
        }

        startPoint = Point(line: startLine, column: startColumn, offset: start)
        endPoint = Point(line: endLine, column: endColumn, offset: end)
        return Position(start: startPoint, end: endPoint, indent: nil)
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
