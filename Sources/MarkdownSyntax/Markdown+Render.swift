//
//  Markdown+Render.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-29.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

/// Document rendering methods.
public extension Markdown {

    /// Parses a AST
    ///
    /// - Returns:
    ///     A Swift AST (Abstract Syntax Tree).
    func parse() -> Root {
        Root(
            children: parseContent(document.node.children),
            position: position(for: document.node)
        )
    }

    /// Renders the document as HTML.
    ///
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the HTML.
    /// - Returns:
    ///     The HTML as a string.
    func renderHtml() async throws -> String {
        try await document.renderHtml()
    }

    /// Renders the document as XML.
    ///
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the XML.
    /// - Returns:
    ///     The XML as a string.
    func renderXml() async throws -> String {
        try await document.renderXml()
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
        try await document.renderMan(width: width)
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
        try await document.renderCommonMark(width: width)
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
        try await document.renderLatex(width: width)
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
        try await document.renderPlainText(width: width)
    }
}
