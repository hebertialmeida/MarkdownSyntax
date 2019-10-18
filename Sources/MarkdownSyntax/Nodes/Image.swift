//
//  Image.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

import Foundation

public struct Image: StaticPhrasingContent, PhrasingContent, Parent, Resource, Alternative {
    public let type: NodeType = .image
    public let url: URL
    public let title: String?
    public let alt: String?
    public let children: [PhrasingContent]
    public let position: Position

    public init(url: URL, title: String?, alt: String?, children: [PhrasingContent], position: Position) {
        self.url = url
        self.title = title
        self.alt = alt
        self.children = children
        self.position = position
    }
}
