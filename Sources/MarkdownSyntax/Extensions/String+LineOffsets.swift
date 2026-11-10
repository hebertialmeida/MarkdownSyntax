//
//  String+LineOffsets.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

extension String {

    /// The index where each line starts, the first line included.
    ///
    /// `\r\n` is one line break, and so is a lone `\r` or `\n`, as cmark counts lines. The scan
    /// reads UTF-8 bytes: both bytes are ASCII, so they never occur inside a multibyte scalar,
    /// and no grapheme breaking is needed to find them.
    var lineOffsets: [String.Index] {
        var result = [startIndex]
        let utf8 = self.utf8
        var index = utf8.startIndex
        while index != utf8.endIndex {
            let byte = utf8[index]
            var next = utf8.index(after: index)
            if byte == UInt8(ascii: "\r"), next != utf8.endIndex, utf8[next] == UInt8(ascii: "\n") {
                next = utf8.index(after: next)
                result.append(next)
            } else if byte == UInt8(ascii: "\n") || byte == UInt8(ascii: "\r") {
                result.append(next)
            }
            index = next
        }
        return result
    }
}
