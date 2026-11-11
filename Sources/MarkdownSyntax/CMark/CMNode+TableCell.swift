//
//  CMNode+TableCell.swift
//  MarkdownSyntax
//
//  A GFM table reads `\|` in a cell as `|` before it parses the cell's inlines
//  (`unescape_pipes`, table.c), and cmark places those inlines in that shorter text: every `\|`
//  written before a node moves its reported columns one byte early. The cell itself is placed
//  from the source and is right. Positions of the nodes inside are mapped back to the source here.
//

import cmark_gfm

extension CMNodeView {

    /// The table cell this node sits in, through any inline containers, or `nil` when it isn't in
    /// one. One step up for a node outside tables: its parent is a block.
    var enclosingCell: CMNodeView? {
        var cursor = parent
        while let current = cursor {
            switch current.rawType {
            case CMNodeExtensionType.tableCell.rawValue:
                return current
            case CMARK_NODE_EMPH.rawValue, CMARK_NODE_STRONG.rawValue, CMARK_NODE_LINK.rawValue,
                 CMARK_NODE_IMAGE.rawValue, CMARK_NODE_CUSTOM_INLINE.rawValue,
                 CMNodeExtensionType.strikethrough.rawValue:
                cursor = current.parent
            default:
                return nil
            }
        }
        return nil
    }
}

extension TreeBuilder {

    /// The table cell a node sits in, if any.
    func enclosingCell(of node: CMNodeView) -> CMNodeView? {
        node.enclosingCell
    }

    /// A node's position with each `\|` its cell holds before it counted, when the node sits in
    /// a table cell that holds one; otherwise `position` unchanged.
    func positionInCell(_ position: Position, of node: CMNodeView) -> Position {
        guard
            let cell = node.enclosingCell,
            case let cellPosition = cell.position(in: text, using: lineOffsets),
            let cellStart = cellPosition.start.offset,
            let cellEnd = cellPosition.end.offset,
            let start = position.start.offset,
            let end = position.end.offset,
            cellStart <= start
        else { return position }

        let utf8 = text.utf8
        let cellBytes = utf8[cellStart...cellEnd]
        guard cellBytes.contains(0x5C) else { return position }

        // Walk the cell's source and the text the table made of it side by side: a `\|` is two
        // bytes of source and one of that text. Each node start maps to the first source byte of
        // the byte it was placed at, each end to the last.
        let startDistance = utf8.distance(from: cellStart, to: start)
        let endDistance = utf8.distance(from: cellStart, to: end)
        var mappedStart: String.Index?
        var mappedEnd: String.Index?
        var placed = 0
        var cursor = cellStart
        while cursor <= cellEnd, mappedEnd == nil {
            let next = utf8.index(after: cursor)
            let isEscapedPipe = utf8[cursor] == 0x5C && next <= cellEnd && utf8[next] == 0x7C
            let last = isEscapedPipe ? next : cursor
            if placed == startDistance { mappedStart = cursor }
            if placed == endDistance { mappedEnd = last }
            placed += 1
            cursor = utf8.index(after: last)
        }
        guard let mappedStart, let mappedEnd else { return position }

        let startShift = utf8.distance(from: start, to: mappedStart)
        let endShift = utf8.distance(from: end, to: mappedEnd)
        return Position(
            start: Point(line: position.start.line, column: position.start.column + startShift, offset: mappedStart),
            end: Point(line: position.end.line, column: position.end.column + endShift, offset: mappedEnd),
            indent: position.indent
        )
    }

    /// The text cmark makes of a source range read as text: backslash escapes of ASCII
    /// punctuation and entity and numeric character references resolved (`handle_backslash`
    /// and `handle_entity`, inlines.c). In a table cell, `\|` is read as `|` first, as the table
    /// does before parsing the cell.
    func literal(of range: Range<String.Index>, inCell: Bool) -> String {
        var bytes = Array(text.utf8[range])
        if inCell {
            var unescaped: [UInt8] = []
            unescaped.reserveCapacity(bytes.count)
            var index = 0
            while index < bytes.count {
                if bytes[index] == 0x5C, index + 1 < bytes.count, bytes[index + 1] == 0x7C { index += 1 }
                unescaped.append(bytes[index])
                index += 1
            }
            bytes = unescaped
        }
        guard bytes.contains(where: { $0 == 0x5C || $0 == 0x26 }) else {
            return String(decoding: bytes, as: UTF8.self)
        }

        var output: [UInt8] = []
        output.reserveCapacity(bytes.count)
        var entity = cmark_strbuf()
        cmark_strbuf_init(cmark_get_default_mem_allocator(), &entity, 0)
        defer { cmark_strbuf_free(&entity) }

        bytes.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            var index = 0
            while index < buffer.count {
                let byte = buffer[index]
                if byte == 0x5C, index + 1 < buffer.count, cmark_ispunct(CChar(bitPattern: buffer[index + 1])) != 0 {
                    output.append(buffer[index + 1])
                    index += 2
                    continue
                }
                if byte == 0x26, index + 1 < buffer.count {
                    cmark_strbuf_clear(&entity)
                    let length = Int(houdini_unescape_ent(&entity, base + index + 1, bufsize_t(buffer.count - index - 1)))
                    if length > 0, let decoded = entity.ptr {
                        output.append(contentsOf: UnsafeBufferPointer(start: decoded, count: Int(entity.size)))
                        index += 1 + length
                        continue
                    }
                }
                output.append(byte)
                index += 1
            }
        }
        return String(decoding: output, as: UTF8.self)
    }
}
