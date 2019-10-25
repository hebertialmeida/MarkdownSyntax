//
//  String+Range.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2019-10-22.
//  Copyright © 2019 Heberti Almeida. All rights reserved.
//

extension String {
//    subscript (bounds: CountableClosedRange<Int>) -> Substring {
//        return self[range(bounds)]
//    }

    /// Helper function for creating `ClosedRange<String.Index>` from `Int` range
    /// - Parameter bounds: Closed range eg. `0...5`
    func range(_ bounds: CountableClosedRange<Int>) -> ClosedRange<Self.Index> {
        let lastValidIndex = index(before: endIndex)
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound, limitedBy: lastValidIndex) ?? lastValidIndex
        return start ... end
    }
}
