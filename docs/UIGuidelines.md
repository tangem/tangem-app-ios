# UI Guidelines

Rules for any UI code in this repository that a linter can't check. Read this page before writing or changing UI; reviewers check UI diffs against it (see the `code-review-tangem-must-checks` skill).

**DS3** is the current design system: the components in `Modules/TangemUI/DesignSystem_V2/` plus the generated tokens `DesignSystem.Color.*` and `DesignSystem.Font.*Token` (`Modules/TangemAssets/Generated/DesignSystem/`). Building or changing a DS3 component itself follows the `ds-component` skill on top of this page.

## Use existing components

Before writing a view, work out how existing DS3 components do it — as they are, or composed together. Only DS3 counts as existing: the previous-generation components in `Modules/TangemUI/DesignSystem/` (`TangemButton`, `TangemRow`, …), pre-DS views (`MainButton`, `Tangem/UILegacy/*`, …) and feature-local lookalikes are debt, even when the neighbouring code uses them.

DS3 doesn't cover everything yet. For these needs, use the listed component until DS3 has its own:

| Need | Use |
|---|---|
| On/off setting (switch) | Native SwiftUI `Toggle`. DS3 `Checkbox` / `Checkmark` are for selection only. |
| Toast / snackbar | `TangemSnackbar`. Legacy `Toast` stays only where it is already used. |

When nothing fits, check the [💠 DS Components](https://www.figma.com/design/AsnJ5CPHib4Qxw12gszjMS/) Figma file:
- the design system has it as a component → it is a missing DS3 component: build it in `DesignSystem_V2` with the `ds-component` skill, not in the feature;
- otherwise → write it in the feature, from DS3 components and tokens.

## Tokens

Pick a token by its role, not by how it looks:

| Painting | Token group |
|---|---|
| Text | `text*` |
| Glyphs and icons | `icon*` |
| Strokes and separators | `border*` |
| Fills and surfaces | `bg*` |

A token that matches by color but belongs to another role is wrong — an `icon*` token on text breaks as soon as the two roles diverge in a theme.

If the design uses a token that has no generated Swift counterpart, stop and ask the developer, linking the Figma node. Don't substitute the nearest token and don't write a raw value: a missing token is usually a DS-Core desync or a gap on the design side, and a guess hides it.

## Accessibility

**RTL.** Use leading/trailing, never left/right. Directional glyphs (arrows, chevrons) mirror. Place overlays such as badges and cut-outs with an alignment plus negative padding (`.overlay(alignment: .bottomTrailing)`), never `offset(x:)`, which doesn't mirror.

**Dynamic Type.** Text never sits in a fixed-height frame that clips it at larger sizes. A raw size passed into a component (`CGFloat`) is used as given — the caller scales it if it should scale.

**Reduce Transparency.** Before applying `.glassEffect` or a blur by hand, try `tangemMaterialSurface(...)` (`Modules/TangemUI/DesignSystem_V2/Material/MaterialSurface.swift`): it keeps the surfaces consistent and handles the setting in one place. On iOS 26 and later the system glass adapts to the setting by itself; the blur fallback below iOS 26 doesn't read it yet, so a surface that must stay legible there reads `accessibilityReduceTransparency` and swaps to an opaque fill, as `ModalSurface` does.

**VoiceOver.** Keep it light: one combined element per row with a label, a value and traits. Apply it to the button's label rather than around the whole cell, so controls inside the row stay reachable. Placeholders that only reserve space are `.hidden()`, which keeps them out of the accessibility tree. No custom rotors or actions unless the design asks for them.

## Image assets

Danger fails a PR with an asset catalog file over 1.5 MB or a PDF/SVG over 64 KB that embeds a raster (`Dangerfile.precheck`). The rest is up to the author:

**Vector or raster.** SVG is for true vector artwork: icons, glyphs, flat illustrations. A picture with a photo, a render, an effect or a person inside is a raster.

**Where it comes from.** All vector artwork comes from DS-Core as SVG: the `update-dscore` workflow generates it into `Modules/TangemAssets/Assets/DSIcons.xcassets`, which is never edited by hand. Don't add vector PDFs, and adding an SVG to an asset catalog yourself is almost always a mistake — if the icon isn't in DS-Core, ask the designers to add it there. Raster images (onboarding pictures, illustrations with people, effects — anything that isn't curves scaling without loss) go into the bundle by hand: DS-Core doesn't deliver them yet, because Android has no workable pipeline for rasters.

**Raster as PNG or PDF.** A raster goes in as PNG @2x/@3x, or as JPEG when it is opaque. For simplicity it can also be a single PDF with `preserves-vector-representation` off: Xcode slices it into @2x/@3x PNGs at build time, so the app ships the same bitmaps. The PDF page is the size the image is shown at in points, with the raster inside at 3× that — never a 2000×2000 PDF for an asset drawn at 64×64. A raster PDF that Danger rejects goes in as PNG instead.

**`preserves-vector-representation`** only on a vector that is drawn larger than its natural size. With it, every scaled draw renders the PDF again at runtime on the CPU, which gets expensive with heavy PDFs; without it the app draws bitmaps rendered at build time.

**Pixel size.** Export @2x/@3x for the largest size the image gets on screen (points × 3, the widest phone for a full-width image), not larger. A natural size that differs from the layout is fine as long as the view is `.resizable()`.

**Format.** Opaque photos, renders and gradient backgrounds are JPEG, which the catalog stores as is; anything with transparency stays PNG. Never set `"compression-type" : "lossy"`: the HEVC it produces rendered as black-and-green garbage on iOS 18.

**Leftovers.** Delete an imageset in the same change that removes its last use.

**Checking a change.** For pixel size, find where the image is shown and compare the @3x bitmap with the largest size it gets on screen. Flag a raster-backed SVG, a new vector PDF or a hand-added SVG that should come from DS-Core, a raster PDF with `preserves-vector-representation` on or a page larger than the size it is shown at, `preserves-vector-representation` on a vector that is never scaled up, an opaque background in PNG, `"compression-type" : "lossy"`, and an imageset left without references.
