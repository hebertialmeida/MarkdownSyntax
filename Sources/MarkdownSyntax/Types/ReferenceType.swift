//
//  ReferenceType.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// How a reference is written: `[a][b]` (full), `[a][]` (collapsed) or `[a]` (shortcut).
public enum ReferenceType: String, Codable, Sendable {
    case shortcut
    case collapsed
    case full
}
