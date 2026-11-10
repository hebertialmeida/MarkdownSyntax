# Extending the syntax

Add syntax of your own on top of Markdown, recognized while the tree is built.

## Overview

cmark knows CommonMark and GitHub Flavored Markdown. Anything else you write, such as
`==marked text==`, reaches the tree as what cmark makes of it: here, a ``Text`` node with the
equals signs in it. A ``MarkdownExtension`` reads those nodes as they are built and returns nodes
of its own instead, so every reader of the tree meets your syntax as a typed node with its own
ranges, the way it meets a ``Link`` or a ``Heading``.

An extension has three parts:

1. **Its anchors.** The cmark node types its syntax can start in — `.text` for `==…==`. Only
   those nodes are offered to it. See <doc:Anchors>.
2. **A recognizer.** ``MarkdownExtension/recognizePhrasing(in:)`` (or
   ``MarkdownExtension/recognizeBlock(in:)``) reads the anchor through a ``ParseContext`` and
   returns the nodes that replace it, or `nil` to leave it to cmark. Positions come from the
   source, never from a literal. See <doc:Ranges>.
3. **Its nodes.** Structs that conform to ``ExtensionContent`` and to ``PhrasingContent`` or
   ``BlockContent``. Each carries ``ExtensionContent/plain``, the nodes the same source reads as
   without the extension, so a reader that doesn't know it still renders it. See
   <doc:PlainFallback>.

For HTML, the recognizer asks the context to put cmark's rendering of the anchor between markup
of its own. See <doc:HTMLOutput>.

## A complete extension

This one recognizes `==…==` inside a text node, and renders it as `<mark>…</mark>`:

```swift
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
    let anchors: [CMNodeType] = [.text]

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
```

Register it when you create the parser:

```swift
let markdown = try await Markdown(text: "Some ==marked== text", syntaxExtensions: [HighlightExtension()])
let tree = await markdown.parse()
// Root > Paragraph > [Text "Some ", Highlight > [Text "marked"], Text " text"]
let html = try await markdown.renderHtml()
// <p data-sourcepos="1:1-1:20">Some <mark>marked</mark> text</p>
```

The text inside a code span, a code block or an HTML block is never a ``Text`` node, so the
extension is never offered it: `==not==` written in a code span stays code. An escaped `\==` reaches the tree as
text whose literal differs from its source, and the guard leaves it alone.

## Cost

The tree build looks each node's type up in the registered anchors. A node of a type no extension
names costs that lookup and nothing else, and with no extension registered the lookup is skipped.
A recognizer runs inside the build, so what it costs is what it reads: check the cheapest thing
first (a prefix of the source, the next sibling's type) and build nodes only once you know.
