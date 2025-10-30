//
//  CMNode+Task.swift
//  MarkdownSyntax
//
//  Created by Kristopher Baker on 2019/05/23.
//  Copyright © 2019 Kristopher Baker. All rights reserved.
//

import cmark_gfm
import cmark_gfm_extensions

/// Extension properties for tasklist items
public extension CMNode {
    var taskCompleted: Bool? {
        // Only tasklist items should have a taskCompleted value.
        guard humanReadableType == CMExtensionName.tasklist.rawValue else {
            return nil
        }
        return cmark_gfm_extensions_get_tasklist_item_checked(cmarkNode)
    }
}
