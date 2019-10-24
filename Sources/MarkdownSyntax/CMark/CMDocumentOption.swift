//
//  CMDocumentOption.swift
//  MarkdownSyntax
//
//  Created by Kris Baker on 12/20/17.
//  Copyright © 2017 Kristopher Baker. All rights reserved.
//

import libcmark_gfm

/// Represents a cmark document option.
public struct CMDocumentOption: OptionSet {

    /// The raw value.
    public let rawValue: Int32

    /// Creates a document option with the specified value.
    ///
    /// - Parameters:
    ///     - rawValue: The raw value.
    /// - Returns:
    ///     The document option with the specified raw value.
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Default options.
    public static let `default` = CMDocumentOption(rawValue: CMARK_OPT_DEFAULT)

    // MARK: Options affecting rendering

    /// Include a `data-sourcepos` attribute on all block elements.
    public static let sourcepos = CMDocumentOption(rawValue: CMARK_OPT_SOURCEPOS)

    /// Render `softbreak` elements as hard line breaks.
    public static let hardBreaks = CMDocumentOption(rawValue: CMARK_OPT_HARDBREAKS)

    /// Render `softbreak` elements as spaces.
    public static let noBreaks = CMDocumentOption(rawValue: CMARK_OPT_NOBREAKS)

    // MARK: Options affecting parsing

    /// Legacy option (no effect).
    public static let normalize = CMDocumentOption(rawValue: CMARK_OPT_NORMALIZE)

    /// Validate UTF-8 in the input before parsing, replacing illegal
    /// sequences with the replacement character U+FFFD.
    public static let validateUtf8 = CMDocumentOption(rawValue: CMARK_OPT_VALIDATE_UTF8)

    /// Convert straight quotes to curly, --- to em dashes, -- to en dashes.
    public static let smart = CMDocumentOption(rawValue: CMARK_OPT_SMART)

    /// Use GitHub-style <pre lang="x"> tags for code blocks instead of
    /// <pre><code class="language-x">.
    public static let preLang = CMDocumentOption(rawValue: CMARK_OPT_GITHUB_PRE_LANG)

    /// Be liberal in interpreting inline HTML tags.
    public static let liberalHtmlTags = CMDocumentOption(rawValue: CMARK_OPT_LIBERAL_HTML_TAG)

    /// Parse footnotes.
    public static let footnotes = CMDocumentOption(rawValue: CMARK_OPT_FOOTNOTES)

    /// Only parse strikethroughs if surrounded by exactly 2 tildes.
    /// Gives some compatibility with redcarpet.
    public static let strikethroughDoubleTilde = CMDocumentOption(rawValue: CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE)

    /// Use style attributes to align table cells instead of align attributes.
    public static let tablePreferStyleAttributes = CMDocumentOption(rawValue: CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES)

    /// Include the remainder of the info string in code blocks in a separate attribute.
    public static let optFullInfoString = CMDocumentOption(rawValue: CMARK_OPT_FULL_INFO_STRING)

    /// Allow raw HTML and unsafe links, `javascript:`, `vbscript:`, `file:`, and
    /// all `data:` URLs -- by default, only `image/png`, `image/gif`, `image/jpeg`,
    /// or `image/webp` mime types are allowed. Without this option, raw HTML is
    /// replaced by a placeholder HTML comment, and unsafe links are replaced by
    /// empty strings.
    public static let unsafe = CMDocumentOption(rawValue: CMARK_OPT_UNSAFE)

}
