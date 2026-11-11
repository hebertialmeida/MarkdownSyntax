# Ranges

Take every position from the source as written.

## Overview

Every node has a ``Position``: the line, column and offset of its first character and of its last
(``Point/offset`` is a `String.Index` into the source; ``Position/range`` is the closed range
between them). An extension's nodes have the same, for the whole syntax, and a stored property
for each part a reader needs on its own — `contentPosition` for the text between `==` marks,
`markerPosition` for a `[!note]`. ``ExtensionContent/subpositions`` lists them by name.

## From the source, never the literal

cmark resolves entities and escapes in a node's ``SourceNode/literal``: `&amp;` becomes `&`, and
`\=` becomes `=`. Positions computed from a literal are off by every such character. Read the
source instead:

- ``ParseContext/range(of:)`` is the half-open source range a node covers.
- ``ParseContext/source`` is the whole source; search it within that range.
- `position(of:)` on ``ParseContext`` turns a source range back into a ``Position``, with the
  line and the UTF-8 column cmark would give it, so it agrees with every other node's.

When the source can't confirm a match — the literal differs from the source where you expected
your syntax — return `nil`. A node left to cmark is always better than a node with a wrong range.

## Multibyte text and line endings

Columns count UTF-8 bytes from the start of the line, as cmark's do, and `\r\n`, a lone `\r` and a
lone `\n` each end one line. Positions built by the context follow the same rules, so ranges stay
right after any text in any script, and on the last line of a file with no line break at its end.
