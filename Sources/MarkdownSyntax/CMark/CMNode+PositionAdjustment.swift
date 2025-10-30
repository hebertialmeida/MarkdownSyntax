//
//  CMNode+PositionAdjustment.swift
//  MarkdownSyntax
//
//  Created for swift-cmark migration compatibility
//
//  This file compensates for position calculation differences between swift-cmark-gfm
//  and swift-cmark. The new library changed how it reports positions for certain elements:
//
//  1. GFM autolinks (autolink.c:275): Changed from `start - rewind` to `max_rewind - rewind`
//     Result: Off-by-one error in start column
//
//  2. Footnote definitions: Positions now exclude the [^label]: prefix
//

extension CMNode {

    /// Adjusts position to restore syntax delimiters that swift-cmark now excludes.
    ///
    /// - Parameters:
    ///   - text: The source markdown text
    ///   - lineOffsets: Line offset indices
    /// - Returns: Position adjusted to include syntax delimiters
    func adjustedPosition(in text: String, using lineOffsets: [String.Index]) -> Position {
        let pos = position(in: text, using: lineOffsets)

        guard let startOffset = pos.start.offset,
              let endOffset = pos.end.offset,
              startOffset >= text.startIndex,
              endOffset < text.endIndex else {
            return pos
        }

        switch type {
        case .link where isAutolink():
            return adjustAutolinkPosition(pos, in: text, startOffset: startOffset, endOffset: endOffset)
            
        case .footnoteDefinition:
            return adjustFootnotePosition(pos, in: text, startOffset: startOffset)
            
        default:
            return pos
        }
    }

    /// Adjusts autolink position for GFM bare URLs only.
    /// Angle bracket autolinks like <http://example.com> don't need adjustment.
    /// Fix off-by-one: GFM bare URL position includes character before URL
    private func adjustAutolinkPosition(
        _ pos: Position,
        in text: String,
        startOffset: String.Index,
        endOffset: String.Index
    ) -> Position {
        guard startOffset > text.startIndex else {
            return pos
        }

        // Fix off-by-one for GFM bare URLs: position includes character before URL
        let adjustedStart = text.utf8.index(startOffset, offsetBy: 1, limitedBy: endOffset) ?? startOffset
        return Position(
            start: Point(line: pos.start.line, column: pos.start.column + 1, offset: adjustedStart),
            end: pos.end,
            indent: pos.indent
        )
    }

    /// Checks if this is a bare URL autolink (not an explicit Markdown link).
    /// GFM autolinks have their URL as the child text content.
    private func isAutolink() -> Bool {
        guard let childText = firstChild?.literal, let linkURLString = linkDestination else {
            return false
        }

        // GFM expands www.example.com to http://www.example.com
        return childText == linkURLString || linkURLString.hasSuffix(childText)
    }

    /// Adjusts footnote definition position to include [^label]: prefix.
    /// Searches backwards up to 100 chars to find the footnote marker.
    private func adjustFootnotePosition(
        _ pos: Position,
        in text: String,
        startOffset: String.Index
    ) -> Position {
        guard startOffset > text.startIndex else { return pos }
        
        let searchLimit = text.utf8.index(startOffset, offsetBy: -100, limitedBy: text.startIndex) ?? text.startIndex
        let searchRange = searchLimit..<startOffset
        
        // Use native backward search for the [^ pattern
        if let range = text.range(of: "[^", options: .backwards, range: searchRange) {
            let distance = text.utf8.distance(from: range.lowerBound, to: startOffset)
            return Position(
                start: Point(line: pos.start.line, column: pos.start.column - distance, offset: range.lowerBound),
                end: pos.end,
                indent: pos.indent
            )
        }

        return pos
    }
}

