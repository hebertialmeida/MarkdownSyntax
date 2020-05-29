# ☄️ MarkdownSyntax

![](https://github.com/hebertialmeida/MarkdownSyntax/workflows/Swift/badge.svg)
[![codecov](https://codecov.io/gh/hebertialmeida/MarkdownSyntax/branch/master/graph/badge.svg)](https://codecov.io/gh/hebertialmeida/MarkdownSyntax)

MarkdownSyntax is a wrapper on top of the Github Flavoured Markdown that conforms to [mdast](https://github.com/syntax-tree/mdast). It parses markdown and creates a normalized AST so you can use it not only for rendering markdown and syntax highlighting. In addition, you can render to standard cmark formats HTML, XML, Man, Latex, Plain Text.

### Usage

```swift
let input = "Hi this is **alpha**"
let tree = try Markdown(text: input).parse()
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
                        end: MarkdownSyntax.Point(line: 1, column: 20, offset: 19), 
                        indent: nil
                    )
                )
            ], 
            position: Position(
                start: Point(line: 1, column: 1, offset: 0), 
                end: Point(line: 1, column: 20, offset: 19), 
                indent: nil)
        )
    ], 
    position: Position(
        start: Point(line: 1, column: 1, offset: 0), 
        end: Point(line: 1, column: 20, offset: 19), 
        indent: nil
    )
)
```

For more examples checkout the tests [MarkdownSyntaxTests](https://github.com/hebertialmeida/MarkdownSyntax/tree/master/Tests/MarkdownSyntaxTests).

### Installation
#### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding MarkdownSyntax as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/hebertialmeida/MarkdownSyntax", .branch("master"))
]
```

### Acknowledgements

- [cmark](https://github.com/commonmark/cmark)
- [GitHub cmark fork](https://github.com/github/cmark)
- [libcmark_gfm](https://github.com/KristopherGBaker/libcmark_gfm)
