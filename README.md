# Scribbly

Milestone 1 of a native, iPad-first coloring app for children ages 3–6.

## Run

Open `Scribbly.xcodeproj` in Xcode, select an iPad simulator, and run the `Scribbly` scheme. The project targets iPadOS 18 and is generated from `project.yml` with XcodeGen.

## Interaction

- Draw with a finger or Apple Pencil.
- Pan with two fingers and pinch to zoom; **Fit** returns the page to the screen.
- A two-finger tap or the large toolbar button undoes the last action.
- Coloring saves automatically after every completed stroke or fill.

## Architecture

SwiftUI owns the child-facing controls and page picker. A UIKit scroll/canvas bridge handles low-latency coalesced touches and gesture arbitration. `PaintEngine` maintains a separate transparent paint bitmap and command-based history; vector line art is always rendered last. Magic Fill uses a raster boundary mask derived from the same vector artwork. Sessions persist as compact Codable paint actions rather than full images.
