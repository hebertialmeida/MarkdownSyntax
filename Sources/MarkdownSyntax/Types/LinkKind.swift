//
//  LinkKind.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2026-09-09.
//  Copyright © 2026 Heberti Almeida. All rights reserved.
//

/// How a link was written in the source markdown.
///
/// Determined from the **source syntax** at the node's own position, never guessed
/// from the destination string — `[harbor](#harbor)` is an inline link even though
/// its label is a suffix of its destination.
public enum LinkKind: String, Equatable, Sendable {

    /// `[label](destination)` — a label followed by a parenthesised destination.
    case inline

    /// `[label][id]`, `[label][]`, or the shortcut form `[id]`.
    case reference

    /// `<https://example.com>` or a bare GFM URL such as `https://example.com`.
    /// An autolink has no label of its own, so `Link.labelPosition` is `nil`.
    case autolink
}
