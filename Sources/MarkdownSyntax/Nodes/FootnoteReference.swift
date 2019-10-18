//
//  FootnoteReference.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct FootnoteReference: StaticPhrasingContent, PhrasingContent, Association {
    public var type: NodeType = .footnoteReference
    public var identifier: String
    public var label: String?
    public var position: Position

    public init(identifier: String, label: String?, position: Position) {
        self.identifier = identifier
        self.label = label
        self.position = position
    }
}
