//
//  CMNode.swift
//  Maaku
//
//  Created by Kris Baker on 12/20/17.
//  Copyright © 2017 Kristopher Baker. All rights reserved.
//

import Foundation.NSURL
import libcmark_gfm

/// Represents a cmark node.
public class CMNode {

    /// The underlying cmark node pointer.
    public let cmarkNode: UnsafeMutablePointer<cmark_node>

    /// Indicates if the node should be freed when done.
    private let referencedMemoryOwner: CMNode?

    /// Read-only access to the memory owner
    /// This allows extensions (or tests) to query the value.
    var internalMemoryOwner: CMNode? {
        return referencedMemoryOwner
    }

    /// Creates a CMNode with the specified cmark node pointer.
    ///
    /// - Parameters:
    ///     - cmarkNode: The underlying cmark node pointer.
    ///     - memoryOwner: indicates who really owns thememory.
    ///          if this is nil, then this node really owns the memory,
    ///          and it should be freed when this node goes away.
    /// - Returns:
    ///     The CMMnode initialized with the specified cmark node pointer.
    public init(cmarkNode: UnsafeMutablePointer<cmark_node>, memoryOwner potentialMemoryOwner: CMNode?) {
        self.cmarkNode = cmarkNode

        if potentialMemoryOwner == nil {
            // There isn't another object that owns the associated cmarkNode,
            // so record ourself as the owner by setting the value to nil
            self.referencedMemoryOwner = nil
        } else if let actualMemoryOwner = potentialMemoryOwner!.referencedMemoryOwner {
            // The object that was passed in actually references another object.
            // So, use that one so we're all pointing to the base object.
            self.referencedMemoryOwner = actualMemoryOwner
        } else {
            // The object that was passed in owns the memory.
            // Use that object as the memory owner.
            self.referencedMemoryOwner = potentialMemoryOwner
        }
    }

    /// Frees the cmark node pointer if necessary.
    deinit {
        if referencedMemoryOwner == nil {
            // We're the one that really owns the memory, so free it.
            // But only free it if the node doesn't have a parent!
            // If it has a parent, then we either need to remove it from the parent
            // or not free it, because the parent will free it.
            if cmarkNode.pointee.parent == nil {
                cmark_node_free(cmarkNode)
            }
        }
    }
}

/// Node extension properties.
public extension CMNode {

    /// Wraps the cmark node pointer in a CMNode.
    ///
    /// - Parameters:
    ///     cmarkNode: The cmark node pointer.
    /// - Returns:
    ///     The CMMNode wrapping the pointer.
    private func wrap(cmarkNode: UnsafeMutablePointer<cmark_node>?) -> CMNode? {
        guard let node = cmarkNode else {
            return nil
        }

        return CMNode(cmarkNode: node, memoryOwner: self)
    }

    /// The next node.
    var next: CMNode? {
        return wrap(cmarkNode: cmarkNode.pointee.next)
    }

    /// The previous node.
    var previous: CMNode? {
        return wrap(cmarkNode: cmarkNode.pointee.prev)
    }

    /// The parent node.
    var parent: CMNode? {
        return wrap(cmarkNode: cmarkNode.pointee.parent)
    }

    /// The first child.
    var firstChild: CMNode? {
        return wrap(cmarkNode: cmarkNode.pointee.first_child)
    }

    /// The last child.
    var lastChild: CMNode? {
        return wrap(cmarkNode: cmarkNode.pointee.last_child)
    }

    var children: [CMNode] {
        var result: [CMNode] = []

        var child = firstChild
        while let unwrapped = child {
            result.append(unwrapped)
            child = child?.next
        }
        return result
    }

    /// The node type.
    var type: CMNodeType {
        let cmarkNodeType = cmark_node_get_type(cmarkNode)
        return CMNodeType(rawValue: cmarkNodeType.rawValue)
    }

    /// The human readable type.
    var humanReadableType: String? {
        guard let buffer = cmark_node_get_type_string(cmarkNode) else {
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
        guard let buffer = cmark_node_get_string_content(cmarkNode) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The heading level.
    var headingLevel: Int32 {
        return cmark_node_get_heading_level(cmarkNode)
    }

    /// The fenced code info.
    var fencedCodeInfo: String? {
        guard let buffer = cmark_node_get_fence_info(cmarkNode) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The custom on enter value.
    var customOnEnter: String? {
        guard let buffer = cmark_node_get_on_enter(cmarkNode) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The custom on exit value.
    var customOnExit: String? {
        guard let buffer = cmark_node_get_on_exit(cmarkNode) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The list type.
    var listType: CMListType {
        return CMListType(rawValue: cmark_node_get_list_type(cmarkNode).rawValue) ?? .none
    }

    /// The list delimiter type.
    var listDelimiterType: CMDelimiterType {
        return CMDelimiterType(rawValue: cmark_node_get_list_delim(cmarkNode).rawValue) ?? .none
    }

    /// The list starting number.
    var listStartingNumber: Int32 {
        return cmark_node_get_list_start(cmarkNode)
    }

    /// The list tight.
    var listTight: Bool {
        return cmark_node_get_list_tight(cmarkNode) != 0
    }

    /// The link URL as a string.
    var linkDestination: String? {
        guard let buffer = cmark_node_get_url(cmarkNode) else {
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
        guard let buffer = cmark_node_get_title(cmarkNode) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The literal.
    var literal: String? {
        guard let buffer = cmark_node_get_literal(cmarkNode) else {
            return nil
        }

        return String(cString: buffer)
    }

    /// The start line.
    var startLine: Int32 {
        return cmark_node_get_start_line(cmarkNode)
    }

    /// The start column.
    var startColumn: Int32 {
        return cmark_node_get_start_column(cmarkNode)
    }

    /// The end line.
    var endLine: Int32 {
        return cmark_node_get_end_line(cmarkNode)
    }

    /// The end column.
    var endColumn: Int32 {
        return cmark_node_get_end_column(cmarkNode)
    }

    /// Returns an iterator for the node.
    var iterator: Iterator? {
        return Iterator(node: self)
    }

    /// Returns the extension associated with the node, or nil
    /// if no extension. Should only ever return a single extension option value,
    /// as a node can never be associated with multiple extensions
    var `extension`: CMExtensionOption? {
        guard let ext = cmark_node_get_syntax_extension(cmarkNode) else {
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
