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

    /// How the link was written in the source. Derived from the source syntax.
    public let kind: LinkKind

    public let children: [StaticPhrasingContent]
    public let position: Position

    /// Position of the text between the brackets — the part a reader reads.
    ///
    /// A sub-range of ``position``. `nil` when the link has no label of its own: an
    /// autolink (`<url>` or a bare GFM URL), or an empty label such as `[](url)`.
    public let labelPosition: Position?

    public init(
        url: URL,
        title: String?,
        kind: LinkKind = .inline,
        children: [StaticPhrasingContent],
        position: Position,
        labelPosition: Position? = nil
    ) {
        self.url = url
        self.title = title
        self.kind = kind
        self.children = children
        self.position = position
        self.labelPosition = labelPosition
    }
}
