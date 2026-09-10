//
//  CMNode+PositionAdjustment.swift
//  MarkdownSyntax
//
//  Created for swift-cmark migration compatibility
//
//  This file compensates for position calculation differences between swift-cmark-gfm
//  and swift-cmark. The new library changed how it reports positions for certain elements:
//
//  1. GFM bare autolinks (autolink.c:275): changed from `start - rewind` to
//     `max_rewind - rewind`. Result: the reported start is one character too early, and
//     the surrounding text nodes are left with stale, overlapping positions.
//
//  2. Footnote definitions: positions now exclude the [^label]: prefix
//
//  Angle autolinks (`<https://example.com>`) and ordinary links are reported correctly
//  and must NOT be adjusted — which is why the classification below reads the source
//  syntax instead of comparing the label against the destination.
//

extension CMNode {

    /// How a `.link` node was written in the source markdown.
    enum LinkSyntax {
        /// `[label](destination)`
        case inline
        /// `[label][id]`, `[label][]`, or the shortcut `[id]`
        case reference
        /// `<https://example.com>`
        case angleAutolink
        /// A bare GFM URL, e.g. `https://example.com` or `www.example.com`
        case bareAutolink

        /// The public classification, which does not distinguish the two autolink forms.
        var kind: LinkKind {
            switch self {
            case .inline: return .inline
            case .reference: return .reference
            case .angleAutolink, .bareAutolink: return .autolink
            }
        }

        var isAutolink: Bool {
            kind == .autolink
        }
    }

    /// Classifies a `.link` node from the **source syntax** at its own position.
    ///
    /// Comparing the label against the destination cannot work: `[harbor](#harbor)` is an
    /// ordinary inline link whose label happens to be a suffix of its destination.
    func linkSyntax(in text: String, using lineOffsets: [String.Index]) -> LinkSyntax {
        let pos = position(in: text, using: lineOffsets)

        guard
            let start = pos.start.offset,
            let end = pos.end.offset,
            start >= text.startIndex,
            end < text.endIndex,
            start <= end
        else {
            // The source could not be inspected (cmark reported an unusable position).
            // Fall back to the shape of the node itself: an autolink's only child is its URL.
            return isAutolinkShaped ? .bareAutolink : .inline
        }

        // Compare in the UTF-8 view: these indices come from UTF-8 offset arithmetic and
        // are not guaranteed to sit on a Character boundary.
        let first = text.utf8[start]
        let last = text.utf8[end]

        guard first == UInt8(ascii: "[") else {
            let isAngle = first == UInt8(ascii: "<") && last == UInt8(ascii: ">")
            return isAngle ? .angleAutolink : .bareAutolink
        }

        switch last {
        case UInt8(ascii: ")"): return .inline
        case UInt8(ascii: "]"): return .reference
        // A bare URL that happens to follow a stray `[`, e.g. `[https://example.com`.
        default: return .bareAutolink
        }
    }

    /// Last-resort shape test used only when the source position is unusable.
    private var isAutolinkShaped: Bool {
        guard let childText = firstChild?.literal, let destination = linkDestination else {
            return false
        }
        // GFM expands www.example.com to http://www.example.com
        return childText == destination || destination.hasSuffix(childText)
    }

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
        case .link:
            switch linkSyntax(in: text, using: lineOffsets) {
            case .bareAutolink:
                return adjustBareAutolinkPosition(pos, in: text, startOffset: startOffset, endOffset: endOffset)
            case .inline, .reference, .angleAutolink:
                return pos
            }

        case .text:
            return adjustTextPosition(pos, in: text, using: lineOffsets)

        case .footnoteDefinition:
            return adjustFootnotePosition(pos, in: text, startOffset: startOffset)

        default:
            return pos
        }
    }

    /// Adjusts position for GFM bare URL autolinks only.
    ///
    /// Angle autolinks like `<http://example.com>` are already reported correctly,
    /// brackets included, and are filtered out before we get here.
    private func adjustBareAutolinkPosition(
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

    /// Repairs the text nodes the GFM autolink extension leaves behind.
    ///
    /// Splitting a paragraph's text around a bare URL leaves two stale positions:
    /// the autolink's own child starts one character too early, and the text node in
    /// front of it still ends inside the URL — overlapping the link.
    private func adjustTextPosition(
        _ pos: Position,
        in text: String,
        using lineOffsets: [String.Index]
    ) -> Position {
        // The autolink's own child spans the URL exactly, so it inherits the link's start.
        if let parent, parent.type == .link,
           parent.linkSyntax(in: text, using: lineOffsets) == .bareAutolink {
            let linkPosition = parent.adjustedPosition(in: text, using: lineOffsets)
            guard let linkStart = linkPosition.start.offset, let start = pos.start.offset,
                  start < linkStart else { return pos }
            return Position(start: linkPosition.start, end: pos.end, indent: pos.indent)
        }

        // The text run in front of a bare autolink still ends inside the URL.
        if let next, next.type == .link,
           next.linkSyntax(in: text, using: lineOffsets) == .bareAutolink {
            let linkPosition = next.adjustedPosition(in: text, using: lineOffsets)
            guard let linkStart = linkPosition.start.offset,
                  let start = pos.start.offset, let end = pos.end.offset,
                  end >= linkStart, linkStart > start, linkStart > text.startIndex
            else { return pos }

            let adjustedEnd = text.utf8.index(before: linkStart)
            return Position(
                start: pos.start,
                end: Point(
                    line: linkPosition.start.line,
                    column: linkPosition.start.column - 1,
                    offset: adjustedEnd
                ),
                indent: pos.indent
            )
        }

        return pos
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
