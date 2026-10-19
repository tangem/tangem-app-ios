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
