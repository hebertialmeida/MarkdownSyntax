//
//  CI.swift
//  MarkdownSyntax
//
//  Created by Heberti Almeida on 2025-08-11.
//

import Foundation

public var isCI: Bool {
    ProcessInfo.processInfo.environment["CI"] == "TRUE"
}
