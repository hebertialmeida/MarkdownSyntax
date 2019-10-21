//
//  FootnoteReference.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct FootnoteReference: StaticPhrasingContent, PhrasingContent, Association {
    public let type: NodeType = .footnoteReference
    public let identifier: String
    public let label: String?
    public let position: Position

    public init(identifier: String, label: String?, position: Position) {
        self.identifier = identifier
        self.label = label
        self.position = position
    }
}
