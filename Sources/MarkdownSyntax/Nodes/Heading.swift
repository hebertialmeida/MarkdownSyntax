//
//  Heading.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct Heading: BlockContent, Parent {
    public let children: [PhrasingContent]
    public let depth: Depth
    public let position: Position

    public init(children: [PhrasingContent], depth: Depth, position: Position) {
        self.children = children
        self.depth = depth
        self.position = position
    }
}

public extension Heading {
    enum Depth: Int, Codable, Sendable {
        case h1 = 1
        case h2 = 2
        case h3 = 3
        case h4 = 4
        case h5 = 5
        case h6 = 6
    }
}
