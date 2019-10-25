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

    func range(_ bounds: CountableClosedRange<Int>) -> ClosedRange<String.Index> {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return start ... end
    }
}
