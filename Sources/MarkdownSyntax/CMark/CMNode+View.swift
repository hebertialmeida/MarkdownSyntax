//
//  CMNode+View.swift
//  MarkdownSyntax
//

import struct Foundation.URL
import cmark_gfm

/// A non-owning view of a cmark node: its pointer, and every read of its fields.
///
/// The tree build reads each node once while its `CMDocument` keeps the whole tree alive, so it
/// walks the pointers through views instead of wrapping each child in a `CMNode`, a class whose
/// memory-owner chain costs an allocation and reference counting per child per `children` read.
/// A view must not outlive the document its node belongs to. `CMNode`'s public reads forward to
/// the same implementation, so the two can't disagree.
struct CMNodeView {

    /// The cmark node read.
    let pointer: UnsafeMutablePointer<cmark_node>

    /// The next sibling.
    var next: CMNodeView? {
        cmark_node_next(pointer).map(CMNodeView.init(pointer:))
    }

    /// The previous sibling.
    var previous: CMNodeView? {
        cmark_node_previous(pointer).map(CMNodeView.init(pointer:))
    }

    /// The parent node.
    var parent: CMNodeView? {
        cmark_node_parent(pointer).map(CMNodeView.init(pointer:))
    }

    /// The first child.
    var firstChild: CMNodeView? {
        cmark_node_first_child(pointer).map(CMNodeView.init(pointer:))
    }

    /// The children, first to last, read as the sequence is iterated.
    var children: Children {
        Children(first: firstChild)
    }

    /// The children of a node, walked through the cmark sibling pointers.
    struct Children: Sequence, IteratorProtocol {
        fileprivate var current: CMNodeView?

        fileprivate init(first: CMNodeView?) {
            current = first
        }

        mutating func next() -> CMNodeView? {
            defer { current = current?.next }
            return current
        }
    }

    /// The node type.
    var type: CMNodeType {
        let pointerType = cmark_node_get_type(pointer)
        return CMNodeType(rawValue: pointerType.rawValue)
    }

    /// The raw cmark node type, which the extension lookup is keyed by.
    var rawType: UInt32 {
        cmark_node_get_type(pointer).rawValue
    }

    /// The human readable type.
    var humanReadableType: String? {
        guard let buffer = cmark_node_get_type_string(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The string value (literal).
    var stringValue: String? {
        return literal
    }

    /// The string content value.
    var stringContent: String? {
        guard let buffer = cmark_node_get_string_content(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The heading level.
    var headingLevel: Int {
        Int(cmark_node_get_heading_level(pointer))
    }

    /// The fenced code info.
    var fencedCodeInfo: String? {
        guard let buffer = cmark_node_get_fence_info(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The custom on enter value.
    var customOnEnter: String? {
        guard let buffer = cmark_node_get_on_enter(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The custom on exit value.
    var customOnExit: String? {
        guard let buffer = cmark_node_get_on_exit(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The list type.
    var listType: CMListType {
        return CMListType(rawValue: cmark_node_get_list_type(pointer).rawValue) ?? .none
    }

    /// The list delimiter type.
    var listDelimiterType: CMDelimiterType {
        return CMDelimiterType(rawValue: cmark_node_get_list_delim(pointer).rawValue) ?? .none
    }

    /// The list starting number.
    var listStartingNumber: Int {
        Int(cmark_node_get_list_start(pointer))
    }

    /// The list tight.
    var listTight: Bool {
        return cmark_node_get_list_tight(pointer) != 0
    }

    /// The link URL as a string.
    var linkDestination: String? {
        guard let buffer = cmark_node_get_url(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The link URL.
    var linkUrl: URL? {
        guard let destination = linkDestination else {
            return nil
        }

        return URL(string: destination)
    }

    /// The link title.
    var linkTitle: String? {
        guard let buffer = cmark_node_get_title(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The literal.
    var literal: String? {
        guard let buffer = cmark_node_get_literal(pointer) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The start line.
    var startLine: Int {
        Int(cmark_node_get_start_line(pointer))
    }

    /// The start column.
    var startColumn: Int {
        Int(cmark_node_get_start_column(pointer))
    }

    /// The end line.
    var endLine: Int {
        Int(cmark_node_get_end_line(pointer))
    }

    /// The end column.
    var endColumn: Int {
        Int(cmark_node_get_end_column(pointer))
    }

    /// Backtick count for code.
    var backtickCount: Int {
        Int(cmark_node_get_backtick_count(pointer))
    }

    /// Returns the extension associated with the node, or nil
    /// if no extension. Should only ever return a single extension option value,
    /// as a node can never be associated with multiple extensions
    var `extension`: CMExtensionOption? {
        guard let ext = cmark_node_get_syntax_extension(pointer) else {
            return nil
        }
        let extName = String(cString: ext.pointee.name)
        let result = CMExtensionOption.option(forExtensionName: extName)
        if result == CMExtensionOption.none {
            return nil
        } else {
            return result
        }
    }
}
