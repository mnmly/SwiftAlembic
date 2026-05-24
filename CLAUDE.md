# SwiftAlembic — agent notes

## Documentation

`SwiftAlembic` ships DocC-generated reference docs (see
`Sources/SwiftAlembic/Documentation.docc/` and `Scripts/build_docs.sh`).
**`///` doc comments on public/`open` symbols are published** to the
static site at https://mnmly.github.io/SwiftAlembic/.

When you add or modify a `public` or `open` declaration:

- Write a `///` doc comment. One-sentence summary, then a paragraph if
  the *why* is non-obvious. Skip restating what the signature already
  says.
- Document each parameter with `- Parameter name:` (use the **internal**
  name when there's an external label — DocC warns otherwise).
- Cross-reference related symbols with double-backtick links, e.g.
  `` ``Alembic/PointsWriter/set(_:)`` ``. DocC link syntax is
  signature-sensitive: `foo(_:)` and `foo(_:_:)` are different.
- When you add a new top-level symbol that belongs in the curated
  sidebar, add it under the appropriate `## Topics` group in
  `Sources/SwiftAlembic/Documentation.docc/SwiftAlembic.md`. Topics
  are organized by *user task*, not alphabetic order.

Verify before declaring documentation work done:

```bash
Scripts/build_docs.sh
```

Expect exit 0 and no new "doesn't exist at" or "external name used to
document parameter" warnings attributable to your changes.

## Platforms

SwiftAlembic targets **macOS 15+, iOS 15+, visionOS 1+, tvOS 15+**
(all arm64). The bundled `Alembic.xcframework` ships device + simulator
slices for every platform. When adding new public surface, make sure it
compiles for every slice — the `Examples/AlembicApp` xcodeproj is the
fastest way to exercise iOS/visionOS link paths.
