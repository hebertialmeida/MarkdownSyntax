//
//  CMIterator.swift
//  MarkdownSyntax
//
//  Created by Kris Baker on 12/20/17.
//  Copyright © 2017 Kristopher Baker. All rights reserved.
//

import cmark_gfm

/// Represents a cmark event type.
public enum CMEventType: UInt32 {

    /// The none event type.
    case none

    /// The done event type.
    case done

    /// The enter event type.
    case enter

    /// The exit event type.
    case exit

    /// The underlying cmark event type.
    var cmarkEventType: cmark_event_type {
        switch self {
        case .none:
            return CMARK_EVENT_NONE
        case .done:
            return CMARK_EVENT_DONE
        case .enter:
            return CMARK_EVENT_ENTER
        case .exit:
            return CMARK_EVENT_EXIT
        }
    }
}

/// Represents a cmark iterator.
public class Iterator {

    /// The underlying cmark iterator pointer.
    private let iterator: UnsafeMutablePointer<cmark_iter>

    private let memoryOwnerNode: CMNode

    /// Creates an iterator for the specified node.
    ///
    /// - Parameters:
    ///     - node: The node.
    /// - Returns:
    ///     The iterator for the node if it could be initalized, nil otherwise.
    public init?(node: CMNode) {
        guard let iter = cmark_iter_new(node.cmarkNode) else {
            return nil
        }

        iterator = iter
        memoryOwnerNode = node
    }

    /// Frees the underlying cmark iterator.
    deinit {
        cmark_iter_free(iterator)
    }

    /// The current node for the iterator.
    public var currentNode: CMNode {
        return CMNode(cmarkNode: cmark_iter_get_node(iterator), memoryOwner: memoryOwnerNode)
    }

    /// The current event type for the iterator.
    public var currentEvent: CMEventType {
        return CMEventType(rawValue: cmark_iter_get_event_type(iterator).rawValue) ?? .none
    }

    /// Resets the iterator to the specified node and event type.
    ///
    /// - Parameters:
    ///     - node: The node.
    ///     - eventType: The event type.
    public func reset(to node: CMNode, eventType: CMEventType) {
        cmark_iter_reset(iterator, node.cmarkNode, eventType.cmarkEventType)
    }

    /// Enumerates the iterator, calling the body closure for each node.
    ///
    /// - Parameters:
    ///     - body: The closure to call for each node visited.
    /// The closure should return true if the enumeration should stop, false otherwise.
    public func enumerate(_ body: ((_ node: CMNode, _ event: CMEventType) throws -> Bool)) throws {
        var stop = false

        while !stop {
            let event = cmark_iter_next(iterator)
            guard event != CMARK_EVENT_DONE else {
                break
            }

            stop = try body(currentNode, currentEvent)
        }
    }
}
