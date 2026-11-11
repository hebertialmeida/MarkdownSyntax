//
//  ExampleExtensions.swift
//  MarkdownSyntaxTests
//
//  Two example syntax extensions, written against the public API only: an inline one that
//  splits a text node (`==highlight==`) and a block one that claims the sibling after its
//  anchor (a `Listing:` paragraph and the code block after it). They are examples for the
//  documentation and the tests; the library ships no syntax of its own.
//
//  The part between the README markers is the README's "Extending the syntax" example, word
//  for word, and the part between the README literal markers its `literal(of:)` example;
//  `ReadmeExampleTests` checks that they stay the same.
//

// README example begin
import Foundation
import MarkdownSyntax

/// Marked text, written `==like this==`.
struct Highlight: StaticPhrasingContent, ExtensionContent {
    /// The marked text.
    let children: [PhrasingContent]
    /// The whole `==…==`, marks included.
    let position: Position
    /// The text between the marks.
    let contentPosition: Position
    /// What the source reads as without the extension: one text node.
    let plain: [Content]

    var subpositions: [String: Position] {
        ["contentPosition": contentPosition]
    }
}

/// Recognizes `==…==` inside a text node, and renders it as `<mark>…</mark>`.
struct HighlightExtension: MarkdownExtension {
    let anchors: [NodeKind] = [.text]

    func recognizePhrasing(in context: inout ParseContext) -> [PhrasingContent]? {
        let source = context.source
        // Ranges come from the source, which differs from the literal where an entity or an
        // escape was written: leave those text nodes to cmark.
        guard
            let range = context.range(of: context.anchor),
            let literal = context.anchor.literal,
            literal[...] == source[range]
        else { return nil }

        var nodes: [PhrasingContent] = []
        var rest = range.lowerBound
        while
            let open = source.range(of: "==", range: rest..<range.upperBound),
            let close = source.range(of: "==", range: open.upperBound..<range.upperBound),
            open.upperBound < close.lowerBound
        {
            let syntax = open.lowerBound..<close.upperBound
            let content = open.upperBound..<close.lowerBound
            guard
                let position = context.position(of: syntax),
                let contentPosition = context.position(of: content)
            else { return nil }

            if rest < open.lowerBound, let before = context.position(of: rest..<open.lowerBound) {
                nodes.append(Text(value: String(source[rest..<open.lowerBound]), position: before))
            }
            nodes.append(Highlight(
                children: [Text(value: String(source[content]), position: contentPosition)],
                position: position,
                contentPosition: contentPosition,
                plain: [Text(value: String(source[syntax]), position: position)]
            ))
            context.wrapHTML(content, in: syntax, onEnter: "<mark>", onExit: "</mark>")
            rest = close.upperBound
        }

        guard !nodes.isEmpty else { return nil }
        if rest < range.upperBound, let after = context.position(of: rest..<range.upperBound) {
            nodes.append(Text(value: String(source[rest..<range.upperBound]), position: after))
        }
        return nodes
    }
}
// README example end

// README literal example begin
/// The text between `[[` and `]]` in a text node, as a reader sees it: `[[Caf&eacute;]]` gives
/// `Café`. The brackets are found in the source, so their ranges stay right where an escape or
/// an entity was written.
func bracketedText(in context: ParseContext) -> String? {
    let source = context.source
    guard
        let range = context.range(of: context.anchor),
        let open = source.range(of: "[[", range: range),
        let close = source.range(of: "]]", range: open.upperBound..<range.upperBound)
    else { return nil }
    return context.literal(of: open.upperBound..<close.lowerBound)
}
// README literal example end

/// A titled code listing: a paragraph that starts `Listing:`, then the code block right after it.
struct Listing: BlockContent, ExtensionContent {
    /// The paragraph's text, `Listing:` included.
    let title: [PhrasingContent]
    /// The code block.
    let code: Code
    /// From the paragraph's first character to the code block's last.
    let position: Position
    /// The `Listing:` marker.
    let markerPosition: Position
    /// What the source reads as without the extension: the paragraph and the code block.
    let plain: [Content]

    var subpositions: [String: Position] {
        ["markerPosition": markerPosition]
    }
}

/// Recognizes a `Listing:` paragraph followed by a code block, claims the code block, and renders
/// both inside `<figure class="listing">`.
struct ListingExtension: MarkdownExtension {
    let anchors: [NodeKind] = [.paragraph]

    private static let marker = "Listing:"

    func recognizeBlock(in context: inout ParseContext) -> [BlockContent]? {
        let source = context.source
        guard
            let range = context.range(of: context.anchor),
            source[range].hasPrefix(Self.marker),
            let next = context.nextUnclaimed, next.kind == .code,
            let codeRange = context.range(of: next),
            let paragraph = context.plainBlock(context.anchor) as? Paragraph,
            let code = context.plainBlock(next) as? Code,
            let markerEnd = source.index(range.lowerBound, offsetBy: Self.marker.count, limitedBy: range.upperBound),
            let markerPosition = context.position(of: range.lowerBound..<markerEnd),
            let position = context.position(of: range.lowerBound..<codeRange.upperBound)
        else { return nil }

        context.claim(through: next)
        context.wrapHTML(onEnter: "<figure class=\"listing\">", onExit: "</figure>")
        return [Listing(title: paragraph.children, code: code, position: position, markerPosition: markerPosition, plain: [paragraph, code])]
    }
}
