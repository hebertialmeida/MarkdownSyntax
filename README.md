# ☄️ MarkdownSyntax

![](https://github.com/hebertialmeida/MarkdownSyntax/workflows/Swift/badge.svg)
[![codecov](https://codecov.io/gh/hebertialmeida/MarkdownSyntax/branch/master/graph/badge.svg)](https://codecov.io/gh/hebertialmeida/MarkdownSyntax)

MarkdownSyntax is a wrapper on top of the GitHub Flavoured Markdown that conforms to [mdast](https://github.com/syntax-tree/mdast). It parses markdown and creates a normalized AST so you can use it not only for rendering markdown and syntax highlighting. In addition, you can render to standard markdown formats: HTML, XML, Man, LaTeX, Plain Text.

If you want to see a real-world usage of MarkdownSyntax, check out https://pinery.app where this framework was designed for.

### Usage

```swift
let input = "Hi this is **alpha**"
let tree = try await Markdown(text: input).parse()
```

Outputs a normalized tree:

```swift
Root(
    children: [
        Paragraph(
            children: [
                Text(
                    value: "Hi this is ",
                    position: Position(
                        start: Point(line: 1, column: 1, offset: 0),
                        end: Point(line: 1, column: 11, offset: 10),
                        indent: nil
                    )
                ),
                Strong(
                    children: [
                        Text(
                            value: "alpha",
                            position: Position(
                                start: Point(line: 1, column: 14, offset: 13),
                                end: Point(line: 1, column: 18, offset: 17),
                                indent: nil
                            )
                        )
                    ],
                    position: Position(
                        start: Point(line: 1, column: 12, offset: 11),
                        end: Point(line: 1, column: 20, offset: 19),
                        indent: nil
                    )
                )
            ],
            position: Position(
                start: Point(line: 1, column: 1, offset: 0),
                end: Point(line: 1, column: 20, offset: 19),
                indent: nil
            )
        )
    ],
    position: Position(
        start: Point(line: 1, column: 1, offset: 0),
        end: Point(line: 1, column: 20, offset: 19),
        indent: nil
    )
)
```

### Extending the syntax

Syntax of your own, on top of Markdown, is a `MarkdownExtension`. It names the cmark node types
its syntax starts in (its *anchors*), and the tree build offers it those nodes in the same walk
that builds the tree. It returns nodes of its own, with positions read from the source, or `nil`
to leave the node to cmark. Each node carries `plain`, what the same source reads as without the
extension, so code that reads the tree and doesn't know your node still renders it.

This extension recognizes `==marked text==` and renders it as `<mark>`:

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
```

Register it when you create the parser:

```swift
let markdown = try await Markdown(text: "Some ==marked== text", syntaxExtensions: [HighlightExtension()])
let tree = await markdown.parse()
// Root > Paragraph > [Text "Some ", Highlight > [Text "marked"], Text " text"]
let html = try await markdown.renderHtml()
// <p data-sourcepos="1:1-1:20">Some <mark>marked</mark> text</p>
```

A node of a type no extension names costs one lookup, and with no extension registered the tree is
built exactly as before. The documentation catalog
([`MarkdownSyntax.docc`](Sources/MarkdownSyntax/MarkdownSyntax.docc)) has an article each on
anchors and claiming siblings, ranges, the `plain` fallback and HTML output.

For more examples checkout the tests [MarkdownSyntaxTests](https://github.com/hebertialmeida/MarkdownSyntax/tree/master/Tests/MarkdownSyntaxTests).

### Installation
#### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding MarkdownSyntax as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/hebertialmeida/MarkdownSyntax", from: "1.3.0")
]
```

### Acknowledgements

- [swift-cmark](https://github.com/swiftlang/swift-cmark)
- [libcmark_gfm](https://github.com/KristopherGBaker/libcmark_gfm)