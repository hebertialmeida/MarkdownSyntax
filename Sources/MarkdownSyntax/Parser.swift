//
//  DocumentConverter.swift
//  Maaku
//
//  Created by Kris Baker on 12/20/17.
//  Copyright © 2017 Kristopher Baker. All rights reserved.
//

/// Represents a way of converting a CMDocument to a Document
public class Parser {

    /// The converted block nodes.
//    private var nodes: [Node] = []

    /// The current footnote index.
    private var footnoteIndex: Int = 0

    /// Creates a document converter.
    ///
    /// - Returns:
    ///     The initialized converter.
    public init() {}

    /// Converts a single CMNode (and its children) to a Swift AST.
    ///
    /// - Parameters:
    ///     - text: The input string.
    /// - Throws:
    ///     `CMParseError.invalidEventType` if an invalid event type is encountered.
    /// - Returns:
    ///     The converted Node.
    public func parse(text: String, startingFootnoteIndex: Int = 0) throws -> Root {

        footnoteIndex = startingFootnoteIndex

        let cmNode = try CMDocument(text: text, options: [.sourcepos, .strikethroughDoubleTilde, .footnotes], extensions: [.all]).node

        func parsePhrasingContent(_ nodes: [CMNode] = []) throws -> [PhrasingContent] {
            var items = [PhrasingContent]()

            for node in nodes {
                switch node.type {
                case .text:
                    guard let value = node.literal else { break }
                    items.append(Text(value: value, position: node.position))

                case .emphasis:
                    items.append(Emphasis(children: try parsePhrasingContent(node.children), position: node.position))

                case .strong:
                    items.append(Strong(children: try parsePhrasingContent(node.children), position: node.position))

                case .code:
                    guard let value = node.literal else { break }
                    items.append(InlineCode(value: value, position: node.position))

                case .extension(.strikethrough):
                    items.append(Delete(children: try parsePhrasingContent(node.children), position: node.position))

                case .softBreak:
                    items.append(Break(position: node.position))

                case .link:
                    guard
                        let url = node.linkUrl, let title = node.linkTitle,
                        let children = try parsePhrasingContent(node.children) as? [StaticPhrasingContent]
                    else { break }
                    items.append(Link(url: url, title: title, children: children, position: node.position))

                case .image:
                    guard let url = node.linkUrl, let title = node.linkTitle else { break }
                    let children = try parsePhrasingContent(node.children)
                    let alt = node.getAll(where: { $0.type == .text }).compactMap({$0.literal}).joined(separator: "")
                    items.append(Image(url: url, title: title, alt: alt, children: children, position: node.position))

                case .footnoteReference:
                    guard let value = node.literal else { break }
                    items.append(FootnoteReference(identifier: value, label: value, position: node.position))
                default:
                    break
                }
            }
            return items
        }

        func parseListContent(_ nodes: [CMNode] = [], spread: Bool?) throws -> [ListContent] {
            var items = [ListContent]()

            for node in nodes where node.type == .item {
                let children = try parseBlockContent(node.children)
                items.append(ListItem(checked: node.taskCompleted, spread: spread, children: children, position: node.position))
            }
            return items
        }


        func parseBlockContent(_ nodes: [CMNode] = []) throws -> [BlockContent] {
            var items = [BlockContent]()

            for node in nodes {
                switch node.type {
                case .heading:
                    let children = try parsePhrasingContent(node.children)
                    let depth = Heading.Depth(rawValue: Int(node.headingLevel)) ?? .h6
                    items.append(Heading(children: children, depth: depth, position: node.position))

                case .paragraph:
                    items.append(Paragraph(children: try parsePhrasingContent(node.children), position: node.position))

                case .blockQuote:
                    items.append(Blockquote(children: try parseBlockContent(node.children), position: node.position))

                case .thematicBreak:
                    items.append(ThematicBreak(position: node.position))

                case .codeBlock:
                    guard let value = node.literal else { break }
                    let language = node.fencedCodeInfo
                    items.append(Code(value: value, language: language, meta: nil, position: node.position))

                case .htmlBlock:
                    guard let value = node.literal else { break }
                    items.append(HTML(value: value, position: node.position))

                case .list:
                    let ordered = node.listType == .ordered
                    let start = Int(node.listStartingNumber)
                    let spread = !node.listTight
                    let children = try parseListContent(node.children, spread: spread)
                    items.append(List(ordered: ordered, start: start, spread: spread, children: children, position: node.position))
                default:
                    print("missing:", node.type)
                    break
                }
            }
            return items
        }

        func parseContent(_ nodes: [CMNode] = []) throws -> [Content] {
            var items = [Content]()

            for node in nodes {
                switch node.type {
                case .footnoteDefinition:
                    footnoteIndex += 1
                    let value = "\(footnoteIndex)"
                    let children = try parseBlockContent(node.children)
                    items.append(FootnoteDefinition(identifier: value, label: value, children: children, position: node.position))

                default:
                    items.append(contentsOf: try parseBlockContent([node]))
                }
            }
            return items
        }

        let items = try parseContent(cmNode.children)

//        for node in nodes where node is Content {
//            items.append(node as! Content)
//        }

        return Root(children: items, position: cmNode.position)
    }

}
