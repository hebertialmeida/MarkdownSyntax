//
//  CMNode+Render.swift
//  MarkdownSyntax
//
//  Created by Kristopher Baker on 2019/05/23.
//  Copyright © 2019 Kristopher Baker. All rights reserved.
//

import cmark_gfm

/// Node rendering methods
public extension CMNode {

    /// Renders the node as HTML.
    ///
    /// - Parameters:
    ///     - options: The document options.
    ///     - extensions: The extension options.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the HTML.
    /// - Returns:
    ///     The HTML as a string.
    func renderHtml(_ options: CMDocumentOption, extensions: CMExtensionOption) async throws -> String {
        try renderHtmlNow(options, extensions: extensions)
    }

    /// Renders the node as HTML without suspending.
    internal func renderHtmlNow(_ options: CMDocumentOption, extensions: CMExtensionOption) throws -> String {
        try Self.renderHtmlNow(cmarkNode, options, extensions: extensions)
    }

    /// Renders a cmark node, and what it holds, as HTML without suspending.
    internal static func renderHtmlNow(
        _ cmarkNode: UnsafeMutablePointer<cmark_node>, _ options: CMDocumentOption, extensions: CMExtensionOption
    ) throws -> String {
        var htmlExtensions: UnsafeMutablePointer<cmark_llist>?

        if extensions.contains(.tagfilters), let tagfilter = cmark_find_syntax_extension("tagfilter") {
            htmlExtensions = cmark_llist_append(cmark_get_default_mem_allocator(), nil, tagfilter)
        }

        guard let buffer = cmark_render_html(cmarkNode, options.rawValue, htmlExtensions) else {
            throw CMDocumentError.renderError
        }

        defer {
            free(buffer)
        }

        guard let html = String(validatingCString: buffer) else {
            throw CMDocumentError.renderError
        }

        return html
    }

    /// Renders the node as XML.
    ///
    /// - Parameters:
    ///     - options: The document options.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the XML.
    /// - Returns:
    ///     The XML as a string.
    func renderXml(_ options: CMDocumentOption) async throws -> String {
        try renderXmlNow(options)
    }

    /// Renders the node as XML without suspending.
    internal func renderXmlNow(_ options: CMDocumentOption) throws -> String {
        guard let buffer = cmark_render_xml(cmarkNode, options.rawValue) else {
            throw CMDocumentError.renderError
        }

        defer {
            free(buffer)
        }

        guard let xml = String(validatingCString: buffer) else {
            throw CMDocumentError.renderError
        }

        return xml
    }

    /// Renders the node as groff man page.
    ///
    /// - Parameters:
    ///     - options: The document options.
    ///     - width: The man page width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the man page.
    /// - Returns:
    ///     The man page as a string.
    func renderMan(_ options: CMDocumentOption, width: Int32) async throws -> String {
        try renderManNow(options, width: width)
    }

    /// Renders the node as groff man page without suspending.
    internal func renderManNow(_ options: CMDocumentOption, width: Int32) throws -> String {
        guard let buffer = cmark_render_man(cmarkNode, options.rawValue, width) else {
            throw CMDocumentError.renderError
        }

        defer {
            free(buffer)
        }

        guard let man = String(validatingCString: buffer) else {
            throw CMDocumentError.renderError
        }

        return man
    }

    /// Renders the node as common mark.
    ///
    /// - Parameters:
    ///     - options: The document options.
    ///     - width: The common mark width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the common mark.
    /// - Returns:
    ///     The common mark as a string.
    func renderCommonMark(_ options: CMDocumentOption, width: Int32) async throws -> String {
        try renderCommonMarkNow(options, width: width)
    }

    /// Renders the node as common mark without suspending.
    internal func renderCommonMarkNow(_ options: CMDocumentOption, width: Int32) throws -> String {
        guard let buffer = cmark_render_commonmark(cmarkNode, options.rawValue, width) else {
            throw CMDocumentError.renderError
        }

        defer {
            free(buffer)
        }

        guard let commonMark = String(validatingCString: buffer) else {
            throw CMDocumentError.renderError
        }

        return commonMark
    }

    /// Renders the node as Latex.
    ///
    /// - Parameters:
    ///     - options: The document options.
    ///     - width: The Latex width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the Latex.
    /// - Returns:
    ///     The Latex as a string.
    func renderLatex(_ options: CMDocumentOption, width: Int32) async throws -> String {
        try renderLatexNow(options, width: width)
    }

    /// Renders the node as Latex without suspending.
    internal func renderLatexNow(_ options: CMDocumentOption, width: Int32) throws -> String {
        guard let buffer = cmark_render_latex(cmarkNode, options.rawValue, width) else {
            throw CMDocumentError.renderError
        }

        defer {
            free(buffer)
        }

        guard let latex = String(validatingCString: buffer) else {
            throw CMDocumentError.renderError
        }

        return latex
    }

    /// Renders the node as plain text.
    ///
    /// - Parameters:
    ///     - options: The document options.
    ///     - width: The plain text width.
    /// - Throws:
    ///     `CMDocumentError.renderError` if there is an error rendering the plain text.
    /// - Returns:
    ///     The plain text as a string.
    func renderPlainText(_ options: CMDocumentOption, width: Int32) async throws -> String {
        try renderPlainTextNow(options, width: width)
    }

    /// Renders the node as plain text without suspending.
    internal func renderPlainTextNow(_ options: CMDocumentOption, width: Int32) throws -> String {
        guard let buffer = cmark_render_plaintext(cmarkNode, options.rawValue, width) else {
            throw CMDocumentError.renderError
        }

        defer {
            free(buffer)
        }

        guard let text = String(validatingCString: buffer) else {
            throw CMDocumentError.renderError
        }

        return text
    }

}
