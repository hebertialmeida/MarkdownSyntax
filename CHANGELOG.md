# Changelog

## 1.7.0 — 2026-11-12

Additive; no source change for code built against 1.6.0.

- `ParseContext.literal(of:)` reads a source range as cmark reads text: backslash escapes of ASCII
  punctuation and entity and numeric character references resolved; in a GFM table cell, `\|`
  first reads as `|`. An extension finds its syntax in the source and takes the text a reader sees
  from here. README, the Ranges article and a tested example.
- Nodes inside a GFM table cell that holds `\|` are placed where they are written. The table reads
  `\|` as `|` before it parses the cell, and every escaped pipe before a node moved its range one
  byte early, so a text holding one ended a byte short.
- `wrapHTML(_:in:onEnter:onExit:)` takes a text node with an escape or an entity, and reads the
  text around and `content` as cmark reads text (`literal(of:)`); it returns `false` when an escape
  or a reference spans a bound. It used to refuse such a node.
- Both `wrapHTML` calls work in a GFM table cell: the custom inline node goes inside a node the cell
  can contain and cmark's HTML renders as nothing of its own. They used to return `false` there.
