# Plain fallback

Keep every reader of the tree working when it meets a node it doesn't know.

## Overview

A tree with an extension's nodes is read by code written for cmark's nodes: an editor's
highlighter, a renderer, an exporter. Each ``ExtensionContent`` node carries
``ExtensionContent/plain``, the nodes the same source reads as without the extension. A reader
handles the nodes it knows and reads `plain` for the rest:

```swift
func render(_ nodes: [Content]) {
    for node in nodes {
        switch node {
        case let highlight as Highlight:
            renderHighlight(highlight)
        case let other as ExtensionContent:
            render(other.plain)          // what the tree held without the extension
        case let paragraph as Paragraph:
            renderParagraph(paragraph)
        default:
            break
        }
    }
}
```

Put the cases for your extension's nodes before the case for cmark's node they replace, and the
`ExtensionContent` case before any case that would match them by another protocol.

## What `plain` holds

- An extension that replaces a whole node holds that node, as ``ParseContext/plainBlock(_:)`` or
  ``ParseContext/plainPhrasing(_:)`` gave it, and each sibling it claimed: a listing that claimed
  the code block after its paragraph holds the ``Paragraph`` and the ``Code``. Read in its place,
  the tree is node for node the tree without the extension.
- An extension that recognizes part of a text node holds a ``Text`` over that part, marks
  included. Read in its place, the text and its ranges are the same, in more nodes than cmark's
  one.

Extensions nested inside stay recognized in `plain`: a reader that falls back meets them as nodes
of their own, and falls back again if it doesn't know them either.
