//
//  Markdown.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// Markdown parser
public final actor Markdown {

    /// The current footnote index.
    private var footnoteIndex: Int = 0

    private var lineOffsets: [String.Index] = []

    private var text = ""

    /// The root node of the document.
    public var document: CMDocument

    // MARK: Init

    /// Init a parser.
    ///
    /// - Parameters:
    ///     - text: The input string.
    ///     - startingFootnoteIndex: The index footnote should start.
    ///     - options: The document options.
    ///     - extensions: gfm extensions to enable.
    /// - Throws:
    ///     `CMDocumentError.parsingError` if an invalid event type is encountered.
    /// - Returns:
    ///     The initialized parser.
    public init(text: String, startingFootnoteIndex: Int = 0, options: CMDocumentOption = [.sourcepos, .strikethroughDoubleTilde, .footnotes], extensions: CMExtensionOption = [.all]) async throws {
        self.text = text
        self.footnoteIndex = startingFootnoteIndex
        self.lineOffsets = text.lineOffsets
        self.document = try CMDocument(text: text, options: options, extensions: extensions)
    }

    // MARK: Internal parsing

    func parseContent(_ nodes: [CMNode]) -> [Content] {
        var items = [Content]()

        for node in nodes {
            switch node.type {
            case .footnoteDefinition:
                footnoteIndex += 1
                let value = "\(footnoteIndex)"
                let children = parseBlockContent(node.children)
                items.append(FootnoteDefinition(identifier: value, label: value, children: children, position: position(for: node)))

            default:
                items.append(contentsOf: parseBlockContent([node]))
            }
        }
        return items
    }

    func parsePhrasingContent(_ nodes: [CMNode]) -> [PhrasingContent] {
        var items = [PhrasingContent]()

        for node in nodes {
            switch node.type {
            case .text:
                guard let value = node.literal else { break }
                items.append(Text(value: value, position: position(for: node)))

            case .emphasis:
                items.append(Emphasis(children: parsePhrasingContent(node.children), position: position(for: node)))

            case .strong:
                items.append(Strong(children: parsePhrasingContent(node.children), position: position(for: node)))

            case .code:
                guard let value = node.literal else { break }
                items.append(InlineCode(value: value, position: position(for: node)))

            case .extension(.strikethrough):
                items.append(Delete(children: parsePhrasingContent(node.children), position: position(for: node)))

            case .softBreak:
                items.append(SoftBreak(position: position(for: node)))

            case .lineBreak:
                items.append(Break(position: position(for: node)))

            case .link:
                guard
                    let url = node.linkUrl, let title = node.linkTitle,
                    let children = parsePhrasingContent(node.children) as? [StaticPhrasingContent]
                else { break }
                items.append(Link(url: url, title: title, children: children, position: position(for: node)))

            case .image:
                guard let url = node.linkUrl, let title = node.linkTitle else { break }
                let children = parsePhrasingContent(node.children)
                let alt = node.getAll(where: { $0.type == .text }).compactMap({$0.literal}).joined(separator: "")
                items.append(Image(url: url, title: title, alt: alt, children: children, position: position(for: node)))

            case .footnoteReference:
                guard let value = node.literal else { break }
                items.append(FootnoteReference(identifier: value, label: value, position: position(for: node)))
                
            case .htmlInline:
                guard let value = node.literal else { break }
                items.append(HTML(value: value, position: position(for: node)))
                
            default:
                break
            }
        }
        return items
    }

    func parseTableContent(_ nodes: [CMNode]) -> [TableContent] {
        var items = [TableContent]()

        for node in nodes {
            switch node.type {
            case .extension(.tableRow):
                let isHeader = node.humanReadableType == CMExtensionName.tableHeader.rawValue
                let children = parseRowContent(node.children)
                items.append(TableRow(isHeader: isHeader, children: children, position: position(for: node)))

            default: break
            }
        }
        return items
    }

    func parseRowContent(_ nodes: [CMNode]) -> [RowContent] {
        var items = [RowContent]()

        for node in nodes where node.type == .extension(.tableCell) {
            let children = parsePhrasingContent(node.children)
            items.append(TableCell(children: children, position: position(for: node)))
        }
        return items
    }

    func parseListContent(_ nodes: [CMNode], spread: Bool?) -> [ListContent] {
        var items = [ListContent]()

        for node in nodes where node.type == .item {
            let children = parseBlockContent(node.children)
            items.append(ListItem(checked: node.taskCompleted, spread: spread, children: children, position: position(for: node)))
        }
        return items
    }

    func parseBlockContent(_ nodes: [CMNode]) -> [BlockContent] {
        var items = [BlockContent]()

        for node in nodes {
            switch node.type {
            case .heading:
                let children = parsePhrasingContent(node.children)
                let depth = Heading.Depth(rawValue: Int(node.headingLevel)) ?? .h6
                items.append(Heading(children: children, depth: depth, position: position(for: node)))

            case .paragraph:
                items.append(Paragraph(children: parsePhrasingContent(node.children), position: position(for: node)))

            case .blockQuote:
                items.append(Blockquote(children: parseBlockContent(node.children), position: position(for: node)))

            case .thematicBreak:
                items.append(ThematicBreak(position: position(for: node)))

            case .codeBlock:
                guard let value = node.literal else { break }
                let language = node.fencedCodeInfo
                items.append(Code(value: value, language: language, meta: nil, position: position(for: node)))

            case .htmlBlock:
                guard let value = node.literal else { break }
                items.append(HTML(value: value, position: position(for: node)))

            case .list:
                let ordered = node.listType == .ordered
                let listStartingNumber = Int(node.listStartingNumber)
                let start: Int? = listStartingNumber > 0 ? listStartingNumber : nil
                let spread = !node.listTight
                let children = parseListContent(node.children, spread: spread)
                items.append(List(ordered: ordered, start: start, spread: spread, children: children, position: position(for: node)))

            case .extension(.table):
                let align = node.getTableAlignments()
                let children = parseTableContent(node.children)
                items.append(Table(align: align, children: children, position: position(for: node)))

            default:
                break
            }
        }
        return items
    }

    // MARK: Position

    func position(for node: CMNode) -> Position {
        node.position(in: text, using: lineOffsets)
    }
}
