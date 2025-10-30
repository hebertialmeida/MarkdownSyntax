//
//  CMNode+TableAlign.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-21.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

import cmark_gfm
import cmark_gfm_extensions

extension CMNode {
    func getTableAlignments() -> [AlignType] {
        guard type == .extension(.table) else { return [] }

        let columns = cmark_gfm_extensions_get_table_columns(cmarkNode)
        var alignments = cmark_gfm_extensions_get_table_alignments(cmarkNode)

        var align: [String] = []

        for idx in 0..<columns {
            if let val = alignments?.pointee, let str = String(bytes: [val], encoding: .utf8) {
                align.append(str)
            }

            if idx < (columns - 1) {
                alignments = alignments?.successor()
            }
        }

        return align.map { AlignType(rawValue: $0) }
    }
}
