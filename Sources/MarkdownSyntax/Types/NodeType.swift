//
//  NodeType.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public enum NodeType: String, Codable {
    case root
    case paragraph
    case heading
    case thematicBreak
    case blockquote
    case list
    case listItem
    case table
    case tableRow
    case tableCell
    case html
    case code
    case yaml
    case definition
    case footnoteDefinition
    case text
    case emphasis
    case strong
    case delete
    case inlineCode
    case `break`
    case softBreak
    case link
    case image
    case linkReference
    case imageReference
    case footnote
    case footnoteReference
}
