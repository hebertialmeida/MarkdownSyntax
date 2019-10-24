//
//  CMNodeType.swift
//  MarkdownSyntax
//
//  Created by Honghao Zhang on 4/22/19.
//  Copyright © 2017 Kristopher Baker. All rights reserved.
//

import libcmark_gfm

/// Represents a cmark extension node type.
public enum CMNodeExtensionType: Equatable {
    case strikethrough
    case table
    case tableRow
    case tableCell
    case other(UInt32)

    /// The raw value.
    var rawValue: UInt32 {
        switch self {
        case .strikethrough:
            return CMARK_NODE_STRIKETHROUGH.rawValue
        case .table:
            return CMARK_NODE_TABLE.rawValue
        case .tableRow:
            return CMARK_NODE_TABLE_ROW.rawValue
        case .tableCell:
            return CMARK_NODE_TABLE_CELL.rawValue
        case let .other(rawValue):
            return rawValue
        }
    }

    init(rawValue: UInt32) {
        switch rawValue {
        case CMARK_NODE_STRIKETHROUGH.rawValue:
            self = .strikethrough
        case CMARK_NODE_TABLE.rawValue:
            self = .table
        case CMARK_NODE_TABLE_ROW.rawValue:
            self = .tableRow
        case CMARK_NODE_TABLE_CELL.rawValue:
            self = .tableCell
        default:
            self = .other(rawValue)
        }
    }

    /// Equatable implementation.
    public static func == (lhs: CMNodeExtensionType, rhs: CMNodeExtensionType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

/// Represents a cmark node type.
public enum CMNodeType: Equatable {
    case none
    case document
    case blockQuote
    case list
    case item
    case codeBlock
    case htmlBlock
    case customBlock
    case paragraph
    case heading
    case thematicBreak
    case footnoteDefinition
    case text
    case softBreak
    case lineBreak
    case code
    case htmlInline
    case customInline
    case emphasis
    case strong
    case link
    case image
    case footnoteReference
    case `extension`(CMNodeExtensionType)

    /// The raw value.
    var rawValue: UInt32 {
        switch self {
        case .none:
            return CMARK_NODE_NONE.rawValue
        case .document:
            return CMARK_NODE_DOCUMENT.rawValue
        case .blockQuote:
            return CMARK_NODE_BLOCK_QUOTE.rawValue
        case .list:
            return CMARK_NODE_LIST.rawValue
        case .item:
            return CMARK_NODE_ITEM.rawValue
        case .codeBlock:
            return CMARK_NODE_CODE_BLOCK.rawValue
        case .htmlBlock:
            return CMARK_NODE_HTML_BLOCK.rawValue
        case .customBlock:
            return CMARK_NODE_CUSTOM_BLOCK.rawValue
        case .paragraph:
            return CMARK_NODE_PARAGRAPH.rawValue
        case .heading:
            return CMARK_NODE_HEADING.rawValue
        case .thematicBreak:
            return CMARK_NODE_THEMATIC_BREAK.rawValue
        case .footnoteDefinition:
            return CMARK_NODE_FOOTNOTE_DEFINITION.rawValue
        case .text:
            return CMARK_NODE_TEXT.rawValue
        case .softBreak:
            return CMARK_NODE_SOFTBREAK.rawValue
        case .lineBreak:
            return CMARK_NODE_LINEBREAK.rawValue
        case .code:
            return CMARK_NODE_CODE.rawValue
        case .htmlInline:
            return CMARK_NODE_HTML_INLINE.rawValue
        case .customInline:
            return CMARK_NODE_CUSTOM_INLINE.rawValue
        case .emphasis:
            return CMARK_NODE_EMPH.rawValue
        case .strong:
            return CMARK_NODE_STRONG.rawValue
        case .link:
            return CMARK_NODE_LINK.rawValue
        case .image:
            return CMARK_NODE_IMAGE.rawValue
        case .footnoteReference:
            return CMARK_NODE_FOOTNOTE_REFERENCE.rawValue
        case let .extension(type):
            return type.rawValue
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    init(rawValue: UInt32) {
        switch rawValue {
        case CMARK_NODE_NONE.rawValue:
            self = .none
        case CMARK_NODE_DOCUMENT.rawValue:
            self = .document
        case CMARK_NODE_BLOCK_QUOTE.rawValue:
            self = .blockQuote
        case CMARK_NODE_LIST.rawValue:
            self = .list
        case CMARK_NODE_ITEM.rawValue:
            self = .item
        case CMARK_NODE_CODE_BLOCK.rawValue:
            self = .codeBlock
        case CMARK_NODE_HTML_BLOCK.rawValue:
            self = .htmlBlock
        case CMARK_NODE_CUSTOM_BLOCK.rawValue:
            self = .customBlock
        case CMARK_NODE_PARAGRAPH.rawValue:
            self = .paragraph
        case CMARK_NODE_HEADING.rawValue:
            self = .heading
        case CMARK_NODE_THEMATIC_BREAK.rawValue:
            self = .thematicBreak
        case CMARK_NODE_FOOTNOTE_DEFINITION.rawValue:
            self = .footnoteDefinition
        case CMARK_NODE_TEXT.rawValue:
            self = .text
        case CMARK_NODE_SOFTBREAK.rawValue:
            self = .softBreak
        case CMARK_NODE_LINEBREAK.rawValue:
            self = .lineBreak
        case CMARK_NODE_CODE.rawValue:
            self = .code
        case CMARK_NODE_HTML_INLINE.rawValue:
            self = .htmlInline
        case CMARK_NODE_CUSTOM_INLINE.rawValue:
            self = .customInline
        case CMARK_NODE_EMPH.rawValue:
            self = .emphasis
        case CMARK_NODE_STRONG.rawValue:
            self = .strong
        case CMARK_NODE_LINK.rawValue:
            self = .link
        case CMARK_NODE_IMAGE.rawValue:
            self = .image
        case CMARK_NODE_FOOTNOTE_REFERENCE.rawValue:
            self = .footnoteReference
        default:
            self = .extension(CMNodeExtensionType(rawValue: rawValue))
        }
    }

    /// Equatable implementation.
    public static func == (lhs: CMNodeType, rhs: CMNodeType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}
