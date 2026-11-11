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
  occurrence in the text node, in source order. The text around and `content` are read as cmark
  reads text (``ParseContext/literal(of:)``), so a text node with an escape or an entity, or `\|`
  in a table cell, renders as without the extension: no escape or reference may span a bound of
  `syntax` or `content`.

```swift
context.wrapHTML(content, in: syntax, onEnter: "<mark>", onExit: "</mark>")
// Some ==marked== text  →  <p>Some <mark>marked</mark> text</p>
```

- ``ParseContext/omitHTML(_:)`` is for syntax written right after a node and belonging to it,
  such as an attribute block after an image: claim the siblings cmark read it into, then leave
  it out. The anchor renders as cmark renders it; the siblings the syntax covers don't render,
  and the text the last of them holds after it renders as text. It makes no custom node.

```swift
context.claim(through: lastSiblingOfTheBlock)
context.omitHTML(block)
// ![Fox](fox.png){alt="*red* fox"} runs  →  <p><img src="fox.png" alt="Fox" /> runs</p>
```

Each is kept only if the recognizer returns nodes, and one call asks for one of them, and ``Markdown/renderHtml()`` includes them
whether or not ``Markdown/parse()`` ran first: with extensions, the tree is built once and the
render uses it. `onEnter` and `onExit` are evaluated only when the document renders HTML, so a parse
that never renders, such as an editor's, never builds them.

## How it renders

For the render, each request becomes a cmark custom node — a custom block for an anchor met as
block content, a custom inline node for one met as phrasing content — that takes the nodes'
place, with `onEnter` and `onExit` as its markup, in the parser's own cmark tree; after the
render that tree is cmark's own again. Every renderer of a ``Markdown`` runs on it without
suspending, so its other renderers never see the custom nodes, even when they're called from
other tasks while ``Markdown/renderHtml()`` runs. With syntax extensions,
``Markdown/document`` is not that tree but a cmark parse of the text of its own, made when you
first read it: you can render or walk it from any task, also while ``Markdown/renderHtml()``
runs.

`onEnter` and `onExit` go into the HTML as they are: escape anything taken from the source.

## Where a custom node can't go

A custom node goes where its parent can contain one. Any inline parent can take a custom inline
node: a GFM table cell, which can't contain one, holds it inside a node it can contain and which
cmark's HTML renders as nothing of its own, so the cell's HTML is the same as anywhere else:

```swift
context.wrapHTML(content, in: syntax, onEnter: "<mark>", onExit: "</mark>")
// | ==b\|c== |  →  <td><mark>b|c</mark></td>
```

A block parent that takes only some blocks, such as a list (items only), can't: there, both
`wrapHTML` calls return `false`, nothing is asked for, and the node renders as cmark renders it.
The tree still has your nodes.

cmark renders a wrapped node as though the custom node were its parent. A paragraph in a tight
list renders without `<p>` because its grandparent is the list; wrapped, its grandparent is the
item, and it renders with `<p>`.

## HTML of part of the tree

``Markdown/renderHtml(of:)`` renders nodes of the tree, one after another, as cmark renders them
in the document, with no extension's HTML in it: an image's label set as a caption, say, with
its emphasis, where its `alt` has only the words. It reads cmark's tree in place, so it parses
nothing again.

```swift
let html = try await markdown.renderHtml(of: image.children)
// ![A *red* fox](fox.png)  →  A <em>red</em> fox
```

Each call walks the document to find its nodes. For many parts of one document — every image's
label — ``Markdown/renderHtml(ofEach:)`` renders each group as `renderHtml(of:)` would, with one
walk for them all:

```swift
let captions = try await markdown.renderHtml(ofEach: images.map(\.children))
```
