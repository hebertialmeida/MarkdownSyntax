# ``MarkdownSyntax``

Parse Markdown into a typed tree, with the source position of every node, and extend the syntax
with your own.

## Overview

MarkdownSyntax parses CommonMark and GitHub Flavored Markdown with
[swift-cmark](https://github.com/swiftlang/swift-cmark) and gives you a tree shaped like
[mdast](https://github.com/syntax-tree/mdast): ``Root``, ``Paragraph``, ``Heading``, ``Text`` and
the rest. Every node carries its ``Position`` in the source, so an editor can style exactly the
characters a node was written with.

```swift
let markdown = try await Markdown(text: "Hi this is **alpha**")
let tree = await markdown.parse()
let html = try await markdown.renderHtml()
```

Syntax of your own, such as `==marked text==`, is a ``MarkdownExtension``: it is recognized in
the same walk that builds the tree, and its nodes sit in the tree next to cmark's.

## Topics

### Parsing

- ``Markdown``
- ``Root``
- ``Position``
- ``Point``

### Extending the syntax

- <doc:ExtendingTheSyntax>
- <doc:Anchors>
- <doc:Ranges>
- <doc:PlainFallback>
- <doc:HTMLOutput>
- ``MarkdownExtension``
- ``ParseContext``
- ``SourceNode``
- ``ExtensionContent``

### Block content

- ``BlockContent``
- ``Paragraph``
- ``Heading``
- ``Blockquote``
- ``List``
- ``ListItem``
- ``Code``
- ``Table``
- ``TableRow``
- ``TableCell``
- ``ThematicBreak``
- ``HTML``
- ``FootnoteDefinition``

### Phrasing content

- ``PhrasingContent``
- ``StaticPhrasingContent``
- ``Text``
- ``Emphasis``
- ``Strong``
- ``Delete``
- ``InlineCode``
- ``Link``
- ``Image``
- ``FootnoteReference``
- ``SoftBreak``
- ``Break``
