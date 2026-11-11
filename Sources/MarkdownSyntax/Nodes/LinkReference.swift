//
//  LinkReference.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-18.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// A link through a definition: `[label][id]`.
public struct LinkReference: PhrasingContent, Parent, Reference {
    public let referenceType: ReferenceType
    public let children: [StaticPhrasingContent]
    public let position: Position

    public init(referenceType: ReferenceType, children: [StaticPhrasingContent], position: Position) {
        self.referenceType = referenceType
        self.children = children
        self.position = position
    }
}
