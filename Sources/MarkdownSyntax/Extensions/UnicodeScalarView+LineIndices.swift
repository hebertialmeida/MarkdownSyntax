//
//  UnicodeScalarView+LineIndices.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

extension String.UnicodeScalarView {

    var lineIndices: [String.Index] {
        var result = [startIndex]
        for i in indices where self[i] == "\n" || self[i] == "\r" {
            result.append(index(after: i))
        }
        return result
    }
}
