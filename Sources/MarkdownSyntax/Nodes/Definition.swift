//
//  Definition.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

import struct Foundation.URL

public struct Definition: DefinitionContent, Association, Resource {
    public let type: NodeType = .definition
    public let identifier: String
    public let label: String?
    public let url: URL
    public let title: String?
    public let position: Position

    public init(identifier: String, label: String?, url: URL, title: String?, position: Position) {
        self.identifier = identifier
        self.label = label
        self.url = url
        self.title = title
        self.position = position
    }
}
