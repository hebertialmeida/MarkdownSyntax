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
    public func parse(text: String) throws -> Root {
        let cmNode = try CMDocument(text: text, options: [.sourcepos, .footnotes], extensions: [.all]).node

        func parsePhrasingContent(_ nodes: [CMNode] = []) throws -> [PhrasingContent] {
            var items = [PhrasingContent]()

            for node in nodes {
                switch node.type {
                case .link:
                    guard
                        let url = node.linkUrl, let title = node.linkTitle,
                        let children = try parsePhrasingContent(node.children) as? [StaticPhrasingContent]
                    else { break }
                    items.append(Link(url: url, title: title, children: children, position: node.position))
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
                case .image:
                    guard let url = node.linkUrl, let title = node.linkTitle else { break }
                    let children = try parsePhrasingContent(node.children)
                    let alt = node.visitAll(where: { $0.type == .text }).compactMap({$0.literal}).joined(separator: "")
                    items.append(Image(url: url, title: title, alt: alt, children: children, position: node.position))
                case .extension(.strikethrough):
                    items.append(Delete(children: try parsePhrasingContent(node.children), position: node.position))
                case .softBreak:
                    items.append(Break(position: node.position))
//                case .footnoteDefinition:
//                    items.append(Footnote(children: try parsePhrasingContent(node.children), position: node.position))
//                case .footnoteReference:
//                    items.append(FootnoteReference(identifier: <#T##String#>, label: <#T##String?#>, position: node.position))
                default:
                    break
                }
            }
            return items
        }

//                escape: require('./tokenize/escape'),
//                html: require('./tokenize/html-inline'),
//                reference: require('./tokenize/reference'),

        func parseContent(_ nodes: [CMNode] = []) throws -> [Content] {
            var items = [Content]()

            for node in nodes {
                switch node.type {
                case .paragraph:
                    items.append(Paragraph(children: try parsePhrasingContent(node.children), position: node.position))
                default:
                    break
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
