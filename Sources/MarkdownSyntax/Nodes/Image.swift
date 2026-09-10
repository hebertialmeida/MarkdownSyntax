//
//  Image.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

import struct Foundation.URL

public struct Image: StaticPhrasingContent, PhrasingContent, Parent, Resource, Alternative {
    public let url: URL
    public let title: String?
    public let alt: String?

    public let children: [PhrasingContent]
    public let position: Position

    /// Position of the alt text between the brackets.
    ///
    /// A sub-range of ``position``. `nil` when the image has an empty label, such as `![](url)`.
    public let labelPosition: Position?

    public init(
        url: URL,
        title: String?,
        alt: String?,
        children: [PhrasingContent],
        position: Position,
        labelPosition: Position? = nil
    ) {
        self.url = url
        self.title = title
        self.alt = alt
        self.children = children
        self.position = position
        self.labelPosition = labelPosition
    }
}
