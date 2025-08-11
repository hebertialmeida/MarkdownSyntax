//
//  CMDocument.swift
//  MarkdownSyntax
//
//  Created by Kris Baker on 12/20/17.
//  Copyright © 2017 Kristopher Baker. All rights reserved.
//

import struct Foundation.Data
import cmark_gfm

/// Represents a cmark document error.
public enum CMDocumentError: Error {

    /// The parsing error type.
    case parsingError

    /// The render error type.
    case renderError
}

/// Represents a cmark document.
public class CMDocument: @unchecked Sendable {

    /// The root node of the document.
    public let node: CMNode

    /// The document options.
    private let options: CMDocumentOption

    /// The enabled extensions.
    private let extensions: CMExtensionOption

    /// Creates a document initialized with the specified data using the default options.
    ///
    /// - Parameters:
    ///     - data: The document data.
    /// - Throws:
    ///     `CMDocumentError.parsingError` if there is an error parsing the data.
    /// - Returns:
    ///     The initialized and parsed document.
    public convenience init(data: Data) throws {
        try self.init(data: data, options: .default)
    }

    /// Creates a document initialized with the specified text using the default options.
    ///
    /// - Parameters:
    ///     - text: The document text.
    /// - Throws:
    ///     `CMDocumentError.parsingError` if there is an error parsing the text.
    /// - Returns:
    ///     The initialized and parsed document.
    public convenience init(text: String) throws {
        try self.init(text: text, options: .default, extensions: .all)
    }

    /// Creates a document initialized with the specified text.
    ///
    /// - Parameters:
    ///     - data: The document data.
    ///     - options: The document options.
    /// - Throws:
    ///     `CMDocumentError.parsingError` if there is an error parsing the data.
    /// - Returns:
    ///     The initialized and parsed document.
    public convenience init(data: Data, options: CMDocumentOption) throws {
        guard let text = String(data: data, encoding: .utf8) else {
            throw CMDocumentError.parsingError
        }
        try self.init(text: text, options: options, extensions: .all)
    }

    /// Creates a document initialized with the specified text.
    ///
    /// - Parameters:
    ///     - text: The document text.
    ///     - options: The document options.
    ///     - extensions: gfm extensions to enable.
    /// - Throws:
    ///     `CMDocumentError.parsingError` if there is an error parsing the text.
    /// - Returns:
    ///     The initialized and parsed document.
    public init(text: String, options: CMDocumentOption, extensions: CMExtensionOption) throws {
        self.options = options
        self.extensions = extensions
        cmark_gfm_core_extensions_ensure_registered()

        guard let parser = cmark_parser_new(options.rawValue) else {
            throw CMDocumentError.parsingError
        }

        defer {
            cmark_parser_free(parser)
        }

        try extensions.addToParser(parser)

        cmark_parser_feed(parser, text, text.utf8.count)

        guard let cmarkNode = cmark_parser_finish(parser) else {
            throw CMDocumentError.parsingError
        }

        // This node is the owner of the memory, so we don't have a referenced memory owner
        node = CMNode(cmarkNode: cmarkNode, memoryOwner: nil)
    }

}

/// Document rendering methods.
public extension CMDocument {

    /// Renders the document as HTML.
    ///
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the HTML.
    /// - Returns:
    ///     The HTML as a string.
    func renderHtml() async throws -> String {
        try await node.renderHtml(options, extensions: extensions)
    }

    /// Renders the document as XML.
    ///
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the XML.
    /// - Returns:
    ///     The XML as a string.
    func renderXml() async throws -> String {
        try await node.renderXml(options)
    }

    /// Renders the document as groff man page.
    ///
    /// - Parameters:
    ///     - width: The man page width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the man page.
    /// - Returns:
    ///     The man page as a string.
    func renderMan(width: Int32) async throws -> String {
        try await node.renderMan(options, width: width)
    }

    /// Renders the document as common mark.
    ///
    /// - Parameters:
    ///     - width: The common mark width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the common mark.
    /// - Returns:
    ///     The common mark as a string.
    func renderCommonMark(width: Int32) async throws -> String {
        try await node.renderCommonMark(options, width: width)
    }

    /// Renders the document as Latex.
    ///
    /// - Parameters:
    ///     - width: The Latex width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the Latex.
    /// - Returns:
    ///     The Latex as a string.
    func renderLatex(width: Int32) async throws -> String {
        try await node.renderLatex(options, width: width)
    }

    /// Renders the document as plain text.
    ///
    /// - Parameters:
    ///     - width: The plain text width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the plain text.
    /// - Returns:
    ///     The plain text as a string.
    func renderPlainText(width: Int32) async throws -> String {
        try await node.renderPlainText(options, width: width)
    }

}
