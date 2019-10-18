//
//  ImageReference.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

public struct ImageReference: StaticPhrasingContent, PhrasingContent, Parent, Reference, Alternative {
    public let type: NodeType = .imageReference
    public let referenceType: ReferenceType
    public let alt: String?
    public let children: [PhrasingContent]
    public let position: Position

    public init(referenceType: ReferenceType, alt: String?, children: [PhrasingContent], position: Position) {
        self.referenceType = referenceType
        self.alt = alt
        self.children = children
        self.position = position
    }
}
