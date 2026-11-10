//
//  FixtureGenerator.swift
//  Benchmarks
//
//  Deterministic Markdown for benchmarks and the tree oracle.
//

/// Generates Markdown that exercises every construct the parser maps, from a fixed seed.
///
/// The same seed and size always produce the same bytes, on every platform, so the text can be
/// published with the package and regenerated at will. The words are made up; no copyrighted
/// prose is involved.
///
/// The output mixes headings, nested and task lists, nested block quotes, tables with every
/// alignment, fenced and indented code, inline and reference links, autolinks, images,
/// footnotes, HTML, entities and multibyte text (accents, CJK, emoji, flags and combining marks).
struct FixtureGenerator {

    /// The fixtures the package publishes, about 4, 64 and 128 kB, each from its own seed so
    /// the smaller ones are not prefixes of the larger.
    static func published() -> [(name: String, text: String)] {
        [("generated-4k", 4 * 1024), ("generated-64k", 64 * 1024), ("generated-128k", 128 * 1024)].map { name, bytes in
            var generator = FixtureGenerator(seed: 0x6D61726B646F776E &+ UInt64(bytes))
            return (name, generator.markdown(bytes: bytes))
        }
    }

    private var random: SplitMix64
    private var footnote = 0
    private var reference = 0

    /// Creates a generator.
    ///
    /// - Parameter seed: The seed of the pseudo-random sequence. Equal seeds give equal text.
    init(seed: UInt64) {
        random = SplitMix64(seed: seed)
    }

    /// Returns Markdown of at least `bytes` UTF-8 bytes, ending at a block boundary with `\n`.
    mutating func markdown(bytes: Int) -> String {
        var out = "# \(title())\n\n"
        while out.utf8.count < bytes {
            out += block()
            out += "\n"
        }
        return out
    }

    // MARK: Blocks

    private mutating func block() -> String {
        switch random.next(below: 16) {
        case 0: return "\(String(repeating: "#", count: 2 + random.next(below: 5))) \(inline(words: 3...7))\n"
        case 1: return "\(inline(words: 3...6)) \\\n\(inline(words: 4...9))\n"
        case 2: return bulletList(depth: 0)
        case 3: return orderedList()
        case 4: return taskList()
        case 5: return quote(depth: 0)
        case 6: return table()
        case 7: return fence()
        case 8: return "    \(code())\n    \(code())\n"
        case 9: return ["---\n", "***\n", "___\n"][random.next(below: 3)]
        case 10: return "<div class=\"note\">\n\(sentence())\n</div>\n"
        case 11:
            footnote += 1
            return "\(sentence()) [^n\(footnote)]\n\n[^n\(footnote)]: \(sentence())\n"
        case 12:
            reference += 1
            return "\(inline(words: 3...6)) [\(word())][ref\(reference)] \(inline(words: 2...5)).\n\n[ref\(reference)]: https://example.com/ref/\(reference) \"\(word())\"\n"
        case 13: return "\(title())\n\(["===", "---"][random.next(below: 2)])\n"
        default: return paragraph()
        }
    }

    private mutating func paragraph() -> String {
        (0..<(1 + random.next(below: 3))).map { _ in sentence() }.joined(separator: "\n") + "\n"
    }

    private mutating func bulletList(depth: Int) -> String {
        let indent = String(repeating: "  ", count: depth)
        let marker = ["-", "*", "+"][random.next(below: 3)]
        var out = ""
        for _ in 0..<(2 + random.next(below: 3)) {
            out += "\(indent)\(marker) \(inline(words: 2...8))\n"
            if depth < 2, random.next(below: 4) == 0 {
                out += bulletList(depth: depth + 1)
            }
        }
        return out
    }

    private mutating func orderedList() -> String {
        let start = 1 + random.next(below: 9)
        let delimiter = [".", ")"][random.next(below: 2)]
        var out = ""
        for n in start..<(start + 2 + random.next(below: 3)) {
            out += "\(n)\(delimiter) \(inline(words: 2...8))\n"
            if random.next(below: 5) == 0 {
                out += "\n   \(sentence())\n"
            }
        }
        return out
    }

    private mutating func taskList() -> String {
        (0..<(2 + random.next(below: 3))).map { _ in
            "- [\(random.next(below: 2) == 0 ? " " : "x")] \(inline(words: 2...6))\n"
        }.joined()
    }

    private mutating func quote(depth: Int) -> String {
        let prefix = String(repeating: "> ", count: depth + 1)
        var out = "\(prefix)\(sentence())\n"
        if random.next(below: 3) == 0 {
            out += "\(prefix)\n\(prefix)- \(inline(words: 2...5))\n\(prefix)- \(inline(words: 2...5))\n"
        }
        if depth < 2, random.next(below: 3) == 0 {
            out += "\(prefix)\n" + quote(depth: depth + 1)
        }
        return out
    }

    private mutating func table() -> String {
        let columns = 2 + random.next(below: 3)
        let header = (0..<columns).map { _ in word() }
        let align = (0..<columns).map { _ in [":---", "---:", ":---:", "---"][random.next(below: 4)] }
        var out = "| \(header.joined(separator: " | ")) |\n| \(align.joined(separator: " | ")) |\n"
        for _ in 0..<(1 + random.next(below: 4)) {
            out += "| \((0..<columns).map { _ in inline(words: 1...3) }.joined(separator: " | ")) |\n"
        }
        return out
    }

    private mutating func fence() -> String {
        let language = ["swift", "rust", "", "python", "text"][random.next(below: 5)]
        let fence = random.next(below: 4) == 0 ? "~~~" : "```"
        let body = (0..<(1 + random.next(below: 5))).map { _ in code() }.joined(separator: "\n")
        return "\(fence)\(language)\n\(body)\n\(fence)\n"
    }

    private mutating func code() -> String {
        let name = word()
        switch random.next(below: 4) {
        case 0: return "let \(name) = \"\(word()) \(multibyte())\" // \(word())"
        case 1: return "fn \(name)(x: &str) -> Option<\(word())> { None }"
        case 2: return "if \(name) < 3 && \(word()) > 1 { return [*_*] }"
        default: return "    \(name).\(word())()"
        }
    }

    // MARK: Inlines

    private mutating func sentence() -> String {
        var s = inline(words: 6...16)
        s = s.prefix(1).uppercased() + s.dropFirst()
        return s + [".", "!", "?", "…"][random.next(below: 4)]
    }

    private mutating func title() -> String {
        (0..<(2 + random.next(below: 4))).map { _ in
            let word = word()
            return word.prefix(1).uppercased() + word.dropFirst()
        }.joined(separator: " ")
    }

    private mutating func inline(words range: ClosedRange<Int>) -> String {
        let count = range.lowerBound + random.next(below: range.count)
        return (0..<count).map { _ in span() }.joined(separator: " ")
    }

    private mutating func span() -> String {
        switch random.next(below: 40) {
        case 0: return "**\(word()) \(word())**"
        case 1: return "*\(word())*"
        case 2: return "_\(word())_"
        case 3: return "~~\(word())~~"
        case 4: return "`\(word())()`"
        case 5: return "``a ` \(word())``"
        case 6: return "[\(word()) \(multibyte())](https://example.com/\(word()))"
        case 7: return "[\(word())](/path/\(word()) \"\(word())\")"
        case 8: return "![\(word())](images/\(word()).png)"
        case 9: return "<https://example.org/\(word())>"
        case 10: return "https://www.example.net/\(word())"
        case 11: return ["&amp;", "&copy;", "&#123;", "&#x1F600;", "&nbsp;", "&lt;tag&gt;"][random.next(below: 6)]
        case 12: return "<span>\(word())</span>"
        case 13: return "\\*\(word())\\*"
        case 14: return "***\(word())***"
        case 15, 16, 17, 18: return multibyte()
        default: return word()
        }
    }

    private mutating func word() -> String {
        let syllables = ["ka", "lo", "mi", "ren", "tu", "sa", "vel", "no", "dri", "pa", "the", "quo", "zin", "ar", "es"]
        return (0..<(1 + random.next(below: 3))).map { _ in syllables[random.next(below: syllables.count)] }.joined()
    }

    private mutating func multibyte() -> String {
        let words = ["café", "naïve", "über", "señor", "日本語", "中文", "русский", "ελληνικά",
                     "😀", "🇧🇷", "👩‍💻", "e\u{301}cole", "한국어", "עברית", "math∑∞", "Ångström"]
        return words[random.next(below: words.count)]
    }
}

/// A small, portable pseudo-random generator (SplitMix64), so the fixtures don't depend on the
/// platform's `SystemRandomNumberGenerator`.
struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A value in `0..<bound`.
    mutating func next(below bound: Int) -> Int {
        Int(next() % UInt64(bound))
    }
}
