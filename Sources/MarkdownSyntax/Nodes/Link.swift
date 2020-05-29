//
//  Link.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

import struct Foundation.URL

public struct Link: PhrasingContent, Parent, Resource {
    public let url: URL
    public let title: String?
    public let children: [StaticPhrasingContent]
    public let position: Position

    public init(url: URL, title: String?, children: [StaticPhrasingContent], position: Position) {
        self.url = url
        self.title = title
        self.children = children
        self.position = position
    }
}
