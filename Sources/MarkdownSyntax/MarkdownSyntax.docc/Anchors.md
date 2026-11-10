# Anchors

Name the cmark node your syntax starts in, and read from there.

## Overview

An extension's ``MarkdownExtension/anchors`` are the cmark node types it is offered. The tree
build walks cmark's tree once; at each node it looks the node's type up, and if extensions are
anchored on it, offers the node to each in turn, in the order they were registered. The first
that returns nodes wins. If none does, the node reads as cmark's.

Pick the anchor by where cmark puts your syntax:

| Syntax written… | Anchor | Recognizer |
|---|---|---|
| on the first line of a quote, `> [!kind]` | `.blockQuote` | ``MarkdownExtension/recognizeBlock(in:)`` |
| as a paragraph of its own, `{{name}}` | `.paragraph` | ``MarkdownExtension/recognizeBlock(in:)`` |
| in a fence's info string | `.codeBlock` | ``MarkdownExtension/recognizeBlock(in:)`` |
| after a heading's text, `{#id}` | `.heading` | ``MarkdownExtension/recognizeBlock(in:)`` |
| in running text, `==mark==` | `.text` | ``MarkdownExtension/recognizePhrasing(in:)`` |
| right after an image, `{width=50%}` | `.image` | ``MarkdownExtension/recognizePhrasing(in:)`` |

A block anchor is offered through ``MarkdownExtension/recognizeBlock(in:)`` and a phrasing anchor
through ``MarkdownExtension/recognizePhrasing(in:)``. Nodes inside a list item or a quote are
offered like any other: the build reaches them as it reads the item's or the quote's children.

## Reading the anchor

The ``ParseContext`` has the anchor as a ``SourceNode``: its ``SourceNode/type``, its
``SourceNode/literal`` and the cmark fields of its kind, and its neighbours
(``SourceNode/next``, ``SourceNode/parent``, ``SourceNode/firstChild``). A source node reads
cmark's tree in place, so it is valid only during the call. To read the source, ask the context
for the node's range (see <doc:Ranges>).

To build what the anchor contains, ask the context rather than walking the children yourself:
``ParseContext/plainBlock(_:)`` and ``ParseContext/plainPhrasing(_:)`` give a node as the tree
holds it without your extension, and ``ParseContext/blocks(in:)`` and
``ParseContext/phrasing(in:)`` its children. Extensions inside are recognized as usual, so a
callout inside a callout is two callouts. The anchor is read once however often you ask, and if
you return `nil` after reading it, that reading is the one the tree keeps.

## Claiming siblings

Syntax that spans more than one cmark node, such as a caption paragraph after a table, starts at
the first and claims the rest: ``ParseContext/claim(through:)`` takes a sibling after the anchor,
and the build skips every sibling up to it. ``ParseContext/nextUnclaimed`` is the one to look at
next. Claims are kept only when you return nodes.

Inside a link's label every node must be ``StaticPhrasingContent``, as cmark's are. An extension
node that isn't reads there as its ``ExtensionContent/plain``.
