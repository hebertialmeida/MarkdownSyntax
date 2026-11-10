//
//  main.swift
//  Benchmarks
//
//  Times `Markdown(text:)` and `parse()` over generated or given Markdown.
//
//  Usage (always in release):
//
//      swift run -c release Benchmarks                     # the published generated fixtures
//      swift run -c release Benchmarks --rounds 50 a.md    # your own files
//      swift run -c release Benchmarks --write-fixtures <dir>
//
//  Each line reports the median and the fastest round, in milliseconds, of the document
//  init (line table + cmark), `parse()` (the Swift tree) and both together. Compare builds in
//  alternating runs on a quiet machine; one run on a busy one is not evidence.
//

import Foundation
import MarkdownSyntax

var rounds = 25
var files: [String] = []
var fixturesDirectory: String?

var arguments = CommandLine.arguments.dropFirst().makeIterator()
while let argument = arguments.next() {
    switch argument {
    case "--rounds":
        guard let value = arguments.next().flatMap(Int.init), value > 0 else {
            fatalError("--rounds needs a positive number")
        }
        rounds = value
    case "--write-fixtures":
        guard let value = arguments.next() else { fatalError("--write-fixtures needs a directory") }
        fixturesDirectory = value
    default:
        files.append(argument)
    }
}

if let fixturesDirectory {
    for (name, text) in FixtureGenerator.published() {
        let url = URL(fileURLWithPath: fixturesDirectory).appendingPathComponent("\(name).md")
        try text.write(to: url, atomically: true, encoding: .utf8)
        print("wrote \(url.path)")
    }
    exit(0)
}

var inputs: [(name: String, text: String)] = []
if files.isEmpty {
    inputs = FixtureGenerator.published()
} else {
    for path in files {
        inputs.append(((path as NSString).lastPathComponent, try String(contentsOfFile: path, encoding: .utf8)))
    }
}

func milliseconds(since start: UInt64) -> Double {
    Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
}

func format(_ value: Double) -> String {
    String(format: "%.2f", value)
}

func median(_ values: [Double]) -> Double {
    let sorted = values.sorted()
    return sorted[sorted.count / 2]
}

var medians: [String: Double] = [:]
for (name, text) in inputs {
    var initTimes: [Double] = [], parseTimes: [Double] = [], totals: [Double] = []
    for _ in 0..<rounds {
        let start = DispatchTime.now().uptimeNanoseconds
        let markdown = try await Markdown(text: text)
        let initTime = milliseconds(since: start)
        let parseStart = DispatchTime.now().uptimeNanoseconds
        _ = await markdown.parse()
        let parseTime = milliseconds(since: parseStart)
        initTimes.append(initTime)
        parseTimes.append(parseTime)
        totals.append(initTime + parseTime)
    }
    medians[name] = median(totals)
    print("\(name)  \(text.utf8.count) bytes  init \(format(median(initTimes)))  parse \(format(median(parseTimes)))  total \(format(median(totals))) ms (median of \(rounds), fastest \(format(totals.min() ?? 0)))")
}

if let small = medians["generated-64k"], let large = medians["generated-128k"] {
    print("doubling 64k -> 128k costs \(format(large / small))x")
}
