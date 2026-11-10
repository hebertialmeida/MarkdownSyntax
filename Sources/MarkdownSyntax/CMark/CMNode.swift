//
//  CMNode.swift
//  MarkdownSyntax
//
//  Created by Kris Baker on 12/20/17.
//  Copyright © 2017 Kristopher Baker. All rights reserved.
//

import struct Foundation.URL
import cmark_gfm

/// Represents a cmark node.
public final class CMNode: @unchecked Sendable {

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
    ///     - potentialMemoryOwner: indicates who really owns thememory.
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

    /// A non-owning view of the same node, which every read below goes through.
    internal var view: CMNodeView {
        CMNodeView(pointer: cmarkNode)
    }

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
        view.type
    }

    /// The human readable type.
    var humanReadableType: String? {
        view.humanReadableType
    }

    /// The string value (literal).
    var stringValue: String? {
        view.stringValue
    }

    /// The string content value.
    var stringContent: String? {
        view.stringContent
    }

    /// The heading level.
    var headingLevel: Int {
        view.headingLevel
    }

    /// The fenced code info.
    var fencedCodeInfo: String? {
        view.fencedCodeInfo
    }

    /// The custom on enter value.
    var customOnEnter: String? {
        view.customOnEnter
    }

    /// The custom on exit value.
    var customOnExit: String? {
        view.customOnExit
    }

    /// The list type.
    var listType: CMListType {
        view.listType
    }

    /// The list delimiter type.
    var listDelimiterType: CMDelimiterType {
        view.listDelimiterType
    }

    /// The list starting number.
    var listStartingNumber: Int {
        view.listStartingNumber
    }

    /// The list tight.
    var listTight: Bool {
        view.listTight
    }

    /// The link URL as a string.
    var linkDestination: String? {
        view.linkDestination
    }

    /// The link URL.
    var linkUrl: URL? {
        view.linkUrl
    }

    /// The link title.
    var linkTitle: String? {
        view.linkTitle
    }

    /// The literal.
    var literal: String? {
        view.literal
    }

    /// The start line.
    var startLine: Int {
        view.startLine
    }

    /// The start column.
    var startColumn: Int {
        view.startColumn
    }

    /// The end line.
    var endLine: Int {
        view.endLine
    }

    /// The end column.
    var endColumn: Int {
        view.endColumn
    }

    /// Backtick count for code.
    var backtickCount: Int {
        view.backtickCount
    }

    /// Returns an iterator for the node.
    var iterator: Iterator? {
        return Iterator(node: self)
    }

    /// Returns the extension associated with the node, or nil
    /// if no extension. Should only ever return a single extension option value,
    /// as a node can never be associated with multiple extensions
    var `extension`: CMExtensionOption? {
        view.`extension`
    }
}
