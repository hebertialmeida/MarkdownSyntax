//
//  Strong.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct Strong: StaticPhrasingContent, PhrasingContent, Parent {
    public let type: NodeType = .strong
    public let children: [PhrasingContent]
    public let position: Position

    public init(children: [PhrasingContent], position: Position) {
        self.children = children
        self.position = position
    }
}
