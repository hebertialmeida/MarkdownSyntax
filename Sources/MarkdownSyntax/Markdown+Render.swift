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
    /// With syntax extensions, the tree is built on the first call and every call returns it.
    ///
    /// - Returns:
    ///     A Swift AST (Abstract Syntax Tree).
    func parse() -> Root {
        buildTree().root
    }

    /// Renders the document as HTML.
    ///
    /// With syntax extensions, the HTML includes what each recognized node asked for through
    /// ``ParseContext/wrapHTML(onEnter:onExit:)``, whether or not ``parse()`` ran before. For the
    /// render the cmark tree in ``document`` holds the custom nodes that carry it, and after the
    /// render it is cmark's own again. Every renderer of a parser runs on it without suspending,
    /// so the other renderers never see the custom nodes, even when called concurrently.
    ///
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the HTML.
    /// - Returns:
    ///     The HTML as a string.
    func renderHtml() async throws -> String {
        guard !syntax.isEmpty else {
            return try document.renderHtmlNow()
        }
        // Synchronous from here to the revert, and every other renderer of this parser is
        // synchronous on it too, so none of them sees the tree with the custom nodes in it.
        let applied = try ExtensionHTML.apply(buildTree().html)
        defer { applied.revert() }
        return try document.renderHtmlNow()
    }

    /// Renders the document as XML.
    ///
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the XML.
    /// - Returns:
    ///     The XML as a string.
    func renderXml() async throws -> String {
        try document.renderXmlNow()
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
        try document.renderManNow(width: width)
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
        try document.renderCommonMarkNow(width: width)
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
        try document.renderLatexNow(width: width)
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
        try document.renderPlainTextNow(width: width)
    }
}
