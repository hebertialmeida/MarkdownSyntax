# HTML output

Render an extension's nodes to HTML through cmark's own renderer.

## Overview

``Markdown/renderHtml()`` is cmark's HTML renderer, which renders cmark's tree, not the Swift
tree. An extension gives its HTML from its recognizer, through the ``ParseContext``:

- ``ParseContext/wrapHTML(onEnter:onExit:)`` renders the anchor, and the siblings claimed before
  the call, between `onEnter` and `onExit`. cmark renders the nodes inside as usual.
- `wrapHTML(_:in:onEnter:onExit:)` is for syntax written inside text: `syntax` is the whole of
  it, delimiters included, and `content` the part rendered between `onEnter` and `onExit`. The
  rest of `syntax` is left out, and the text around it renders as before. Call it once for each
  occurrence in the text node, in source order.

```swift
context.wrapHTML(content, in: syntax, onEnter: "<mark>", onExit: "</mark>")
// Some ==marked== text  →  <p>Some <mark>marked</mark> text</p>
```

Both are kept only if the recognizer returns nodes, and ``Markdown/renderHtml()`` includes them
whether or not ``Markdown/parse()`` ran first: with extensions, the tree is built once and both
use it.

## How it renders

For the render, each request becomes a cmark custom node — a custom block for an anchor met as
block content, a custom inline node for one met as phrasing content — that takes the nodes'
place, with `onEnter` and `onExit` as its markup. After the render the tree in
``Markdown/document`` is cmark's own again, so the other renderers, and anything reading the cmark
tree, never see the custom nodes. Don't read ``Markdown/document`` from another task while
``Markdown/renderHtml()`` runs.

`onEnter` and `onExit` go into the HTML as they are: escape anything taken from the source.

## Where a custom node can't go

A custom node goes where its parent can contain one. A GFM table cell can't: there, both
`wrapHTML` calls return `false`, nothing is asked for, and the cell renders as cmark renders it.
The tree still has your nodes.

cmark renders a wrapped node as though the custom node were its parent. A paragraph in a tight
list renders without `<p>` because its grandparent is the list; wrapped, its grandparent is the
item, and it renders with `<p>`.
