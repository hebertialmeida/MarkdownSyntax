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

        // Bare autolinks are handled *before* the offsets are checked, because the whole point is
        // that theirs can be missing: cmark reports start column 0 for a URL that opens a
        // paragraph, `position(in:)` maps nothing, and the URL went unhighlighted entirely.
        if type == .link, linkSyntax(in: text, using: lineOffsets) == .bareAutolink {
            return bareAutolinkPosition(pos, in: text, using: lineOffsets)
        }

        // Likewise a text node, whose repair reads its neighbours rather than its own offsets.
        if type == .text {
            return adjustTextPosition(pos, in: text, using: lineOffsets)
        }

        guard let startOffset = pos.start.offset,
              let endOffset = pos.end.offset,
              startOffset >= text.startIndex,
              endOffset < text.endIndex else {
            return pos
        }

        switch type {
        case .footnoteDefinition:
            return adjustFootnotePosition(pos, in: text, startOffset: startOffset)

        default:
            return pos
        }
    }

    /// Maps a 1-based `(line, column)` pair to an index, or `nil` when it cannot be mapped.
    ///
    /// Deliberately a second, smaller copy of the arithmetic inside `position(in:)`: this needs to
    /// map *one* end of a position while the other is unmappable, which that method — all-or-nothing
    /// by design, and used by every node type — cannot express without changing its contract.
    private func offset(
        line: Int,
        column: Int,
        in text: String,
        using lineOffsets: [String.Index]
    ) -> String.Index? {
        guard line > 0, column > 0, line <= lineOffsets.count, text.startIndex != text.endIndex else {
            return nil
        }
        let lastValidIndex = text.index(before: text.endIndex)
        return text.utf8.index(lineOffsets[line - 1], offsetBy: column - 1, limitedBy: lastValidIndex)
    }

    /// Recovers the start of a GFM bare URL autolink, which cmark does not report as a column.
    ///
    /// The autolink extension reports the start as an **offset into the paragraph's content
    /// buffer**, not a column on the line. On a single-line paragraph the two coincide to within
    /// one character, which is why a `+1` fudge appeared to work. As soon as the paragraph has a
    /// soft line break the error grows by every byte of the preceding lines:
    ///
    /// ```
    /// "line one\na https://one.example.com and https://two.example.com b"
    ///                ↑ actually column 3, reported as column 12  (8 bytes + newline = 9)
    ///                                          ↑ column 31, reported as 40
    /// ```
    ///
    /// Highlighting then painted a *suffix* of each URL and left the front of it as plain text.
    ///
    /// The **end** is reported correctly in every case, so the start is derived from it instead:
    /// walk back the length of the URL as it appears in the source. That needs no knowledge of
    /// where the line began, so it is right on line 1 and line 40 alike, and it replaces the `+1`
    /// rather than compounding it.
    ///
    /// Angle autolinks (`<http://example.com>`) are reported correctly, brackets included, and
    /// are filtered out before they get here.
    private func bareAutolinkPosition(
        _ pos: Position,
        in text: String,
        using lineOffsets: [String.Index]
    ) -> Position {
        // The end is the one thing cmark gets right about a bare autolink — but when the URL opens
        // a paragraph it reports start column 0, `position(in:)` refuses the whole position, and
        // even the end arrives unmapped. Map it from the reported line and column instead.
        guard let endOffset = pos.end.offset
                ?? offset(line: endLine, column: endColumn, in: text, using: lineOffsets),
              endOffset < text.endIndex
        else {
            return pos
        }
        let end = pos.end.offset == nil
            ? Point(line: endLine, column: endColumn, offset: endOffset)
            : pos.end

        // The source text of the link is its own child; `linkDestination` is unusable here
        // because GFM expands `www.example.com` to `http://www.example.com`.
        guard
            let literal = firstChild?.literal,
            case let length = literal.utf8.count,
            length > 0,
            let derivedStart = text.utf8.index(endOffset, offsetBy: -(length - 1), limitedBy: text.startIndex)
        else {
            // Nothing to measure against. Leave the position alone rather than shifting it by a
            // guess — a whole unhighlighted URL is better than a misaligned one.
            return pos
        }

        // `column` cannot be recovered the same way (the line's own start is not known here) and
        // no caller reads it: `Position.range` is built from the offsets. Kept honest by deriving
        // it from the end instead of leaving the buffer offset in place.
        return Position(
            start: Point(line: end.line, column: end.column - (length - 1), offset: derivedStart),
            end: end,
            indent: pos.indent
        )
    }

    /// Repairs the text nodes the GFM autolink extension leaves behind.
    ///
    /// Splitting a paragraph's text around a bare URL leaves two stale positions, both of them
    /// derived from the same paragraph-buffer offset that breaks the link itself:
    ///
    /// * the autolink's **own child** carries the URL as its literal but the link's bad start; and
    /// * the text run **in front of** it still ends inside the URL.
    ///
    /// ```
    /// "line one\na https://one.example.com …"
    ///   text  literal "a "  reported L2:C1-C7   ← two characters long, seven columns wide
    ///   link                reported L2:C11     ← actually column 3
    /// ```
    private func adjustTextPosition(
        _ pos: Position,
        in text: String,
        using lineOffsets: [String.Index]
    ) -> Position {
        // The autolink's own child spans the URL exactly, so it takes the link's whole position.
        // Unconditional: the child's own start is a buffer offset, which lands *after* the true
        // start as often as before it, so there is no ordering test worth making here.
        if let parent, parent.type == .link,
           parent.linkSyntax(in: text, using: lineOffsets) == .bareAutolink {
            let linkPosition = parent.adjustedPosition(in: text, using: lineOffsets)
            guard linkPosition.start.offset != nil else { return pos }
            return linkPosition
        }

        // The text run in front of a bare autolink still ends inside the URL: its true end is the
        // character before the link starts.
        if let next, next.type == .link,
           next.linkSyntax(in: text, using: lineOffsets) == .bareAutolink {
            let linkPosition = next.adjustedPosition(in: text, using: lineOffsets)
            guard let linkStart = linkPosition.start.offset,
                  let start = pos.start.offset, let end = pos.end.offset,
                  end >= linkStart, linkStart > text.startIndex
            else { return pos }

            // `linkStart <= start` means this node has no room to exist — cmark emits such a node
            // with an **empty literal** when the URL opens the line. Clamping it would invert the
            // range, so it is left as it is: it carries no text, and every consumer reads the
            // literal rather than the span.
            guard linkStart > start else { return pos }

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
