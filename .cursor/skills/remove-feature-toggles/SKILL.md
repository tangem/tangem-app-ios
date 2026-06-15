---
description: Remove shipped feature toggles (enum Feature cases) released below a given version — inline the enabled path and mechanically delete the legacy code they gated. Use when asked to remove or clean up feature toggles released before some version (e.g. "remove all the pre-5.39 toggles").
argument: threshold - release version; toggles with releaseVersion strictly below it are removed (e.g. 5.39)
---

# Remove released feature toggles

Mechanical cleanup only: each qualifying toggle is treated as permanently `true`. No refactoring, no renames, no behavior changes beyond deleting the dead disabled path.

The bar for deleting anything is that it is provably dead — no remaining references anywhere (`rg` by name), or unreachable after the inline. Code that still compiles and still has a live caller stays exactly as written, even when the removal leaves it looking redundant — a lone `V2` suffix, a one-case `switch`, an indirection with a single implementation. Renaming, collapsing, and re-shaping such code are judgment calls; leave them to the toggle's author, who is added as a PR reviewer (see Finishing) and can clean up as a follow-up. When unsure whether something is dead or merely ugly, leave it.

## Scope

1. Read `Tangem/FeatureToggles/Feature.swift`. A toggle qualifies when its `releaseVersion` is `.version(v)` with `v` strictly below the threshold. `.unspecified` toggles never qualify.
2. For each qualifying toggle, build the usage list with `rg -n "\b<caseName>\b"` over the whole repo. This catches `FeatureProvider.isAvailable(.x)`, `Feature.x`, raw-string usages in tests, and TODO comments mentioning the toggle. `Feature.swift` itself always contributes 3 entries (case declaration, `name`, `releaseVersion`).

## Inline rules (toggle == true)

- `if FeatureProvider.isAvailable(.x) { A } else { B }` → `A`; delete `B`.
- `guard FeatureProvider.isAvailable(.x) else { ... }` → delete the guard.
- `FeatureProvider.isAvailable(.x) ? new : old` → `new`.
- `isAvailable(.x) || cond` → `true` (usually the whole assignment collapses); `isAvailable(.x) && cond` → `cond`.
- `if FeatureProvider.isAvailable(.x), cond {` → `if cond {`.
- Comments explaining the toggle split (e.g. `// V2: ...`, `// below save old logic`) are deleted together with it. [REDACTED_TODO_COMMENT]

## Dead-code chase

After inlining, repeatedly delete what the inline left unreferenced. Before deleting any symbol or file, confirm it has zero remaining references (`rg` by name); a single live caller means it is not dead — stop there:

- legacy counterpart methods (`somethingLegacy`, V1 variants next to `somethingV2`) and private helpers only they used;
- whole types and files — delete the file from disk; the Xcode project uses file-system-synchronized groups, so `project.pbxproj` normally needs no edits (verify with `rg <FileName> TangemApp.xcodeproj/project.pbxproj`);
- now-unused stored properties, init parameters, and the arguments factories passed for them;
- a parameter the inline leaves entirely unused — drop it from the signature and update every call site; but if it is still passed a meaningful value anywhere, it is not dead, leave the signature alone;
- enum cases nobody constructs anymore (deeplink destinations, story variants) — remove the case and every pattern-match on it (`id` switches, presenter switches, analytics mappings). When sweeping for leftovers, grep the bare member name (`rg '\.caseName\b'`), not just call-shaped patterns like `.caseName(` — bare rows in multi-case lists (`case .a, .caseName, .b:`) are pattern-matches too and won't show up otherwise. Mind that the same member name may exist on unrelated enums: check what each hit switches over before touching it;
- error cases nothing throws anymore — remove their pattern-matches (notification managers, `UniversalError` extensions); in numbered subsystem comment lists, mark the entry `removed. Previously - <TypeName>` (keep the old name so a code seen in an old release build can still be traced) rather than deleting the line, so error codes are not reused;
- unit tests: delete tests of removed legacy paths, drop removed init parameters and mocks. Affected SPM modules count too, not only the app target.

Stop the chase at anything still referenced by live code. If both branches of a `switch` end up with identical bodies after inlining, leave the duplication — collapsing cases is refactoring, not removal.

## What NOT to touch

- Toggles with `.unspecified` release or at/above the threshold.
- Generated files (`Modules/TangemAssets/Generated/`, `Modules/TangemLocalization/Generated/`) and localization keys that became unused — SwiftGen/Lokalise own them; never hand-edit `Generated/`. Surface the orphaned keys in the PR description instead (see Finishing) so a human can deprecate them in Lokalise.
- Naming, structure, and abstractions still referenced by live code — even if the removal makes them look redundant. The line is the reference count, not aesthetics: a type or method left with zero references is dead and gets deleted per the chase above; anything with a live caller stays untouched.

## Finishing

1. Remove each qualifying case from all three switches in `Feature.swift`.
2. Build the app scheme; fix breakage only by further mechanical deletion.
3. Run the affected unit tests (app target and any touched SPM modules).
4. Format what you changed: `mint run swiftformat@0.55.5 <changed paths> --config .swiftformat`.
5. One commit per toggle keeps the PR reviewable; the heavy cascades (deleted flows) may get their own commit.
6. List in the PR description any localization keys the removal orphaned. A key is orphaned when the legacy `Localization.<accessor>` it backs has no references left outside `Generated/` — find them by mapping each deleted string usage to its accessor and confirming `rg --no-ignore '\.<accessor>\b' --glob '!**/Generated/**'` returns nothing (report the Lokalise key from the accessor's `tr("Localizable", "<key>")`). These can't be removed from here (SwiftGen/Lokalise own them), so the description is where someone marks them deprecated by hand.
7. Request the authors of the removed toggles as PR reviewers. For each toggle, find the commit that introduced it and resolve the author's GitHub login:

   ```bash
   git log --reverse -S"case <toggleName>" --format="%h %an %ae" develop -- Tangem/FeatureToggles/Feature.swift | head -1
   gh api repos/tangem-developments/tangem-app-ios/commits/<sha> --jq .author.login
   ```

   Deduplicate the logins and exclude yourself. For authors no longer on the team, fall back to the usual reviewer selection (see the create-pr skill).
8. The standard workflow from AGENTS.md applies: Jira ticket fields, branch naming, self-review before the PR.
