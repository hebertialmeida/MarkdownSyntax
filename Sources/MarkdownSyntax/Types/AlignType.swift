//
//  AlignType.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// Represents how phrasing content is aligned on a Table.
public enum AlignType: String, Codable, Sendable {
    case center = "c"
    case left = "l"
    case none = ""
    case right = "r"

    /// Creates a AlignType matching the raw value.
    ///
    /// - Parameters:
    ///     - rawValue: The raw alignment value.
    /// - Returns:
    ///     - The table alignment matching the raw value,
    ///       TableAlignment.none if there is no match.
    public init(rawValue: String) {
        switch rawValue {
        case AlignType.center.rawValue:
            self = .center
        case AlignType.left.rawValue:
            self = .left
        case AlignType.right.rawValue:
            self = .right
        default:
            self = .none
        }
    }
}
