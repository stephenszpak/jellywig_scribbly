# Coloring page artwork

Drop generated line-art PNGs in this folder, then register each one as a
`ColoringPage` in `Models/ColoringPage.swift` using `.image("filename")`
(no extension) as the `lineArt` source.

## Image requirements

- **Format:** PNG.
- **Lines:** pure black (or near-black), on a transparent or white background.
  Nothing else should be black/dark — the app treats any dark pixel as a
  line-art boundary for both display and Magic Fill.
- **Resolution:** at least 1024x1024 (square). The paint engine's internal
  canvas is 1024x1024, so anything smaller will look soft when zoomed in.
- **Line thickness:** thick, clean, closed outlines — thin or broken lines
  let Magic Fill leak between regions. Aim for lines at least ~1.5% of the
  image width (~15px at 1024x1024). Avoid tiny intricate details; this app
  is for ages 3-6.
- **Regions:** every area meant to be filled (a petal, a shell, a balloon)
  must be a fully closed shape — any gap in the outline lets a fill escape
  into the surrounding artwork.

## Registering a new page

Add an entry to `ColoringPage.samples` in `Models/ColoringPage.swift`:

```swift
.init(id: UUID(), title: "Dinosaur", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur"))
```

The filename passed to `.image(...)` must match the PNG's name in this
folder (without the `.png` extension), e.g. `dinosaur.png`.
