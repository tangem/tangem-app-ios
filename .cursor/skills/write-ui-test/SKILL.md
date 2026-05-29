---
name: write-ui-test
description: Use this skill when writing, modifying, or debugging UI tests for the Tangem iOS app — anything under `TangemUITests/`, page objects under `TangemUITests/Screens/`, accessibility identifiers in `Modules/TangemAccessibilityIdentifiers/`, or API mocks in `../tangem-api-mocks`. Triggers include "write UI test", "add UI test", "create page object", "add accessibility identifier for test", "fix flaky UI test", or any direct request to touch files in those locations. Do NOT use for unit tests (`Tangem*Tests/`), SPM module tests (`Modules/*Tests`), SwiftUI previews, or general production code work — those are different workflows with different rules.
---

# Write UI Test

Act as an experienced iOS developer specializing in UI testing for the Tangem iOS app. Strictly follow the conventions below — they encode decisions that have already been made and re-litigated multiple times.

## 1. Planning phase (MANDATORY before any code)

Before writing or modifying any UI test code, you MUST plan first:

1. Call `EnterPlanMode` to switch to planning mode.
2. Think deeply about edge cases, dependencies, and potential flake sources.
3. Research the codebase: read related tests in `TangemUITests/Tests/`, existing page objects in `TangemUITests/Screens/`, the relevant identifiers file in `Modules/TangemAccessibilityIdentifiers/`, and any related mocks under `../tangem-api-mocks`.
4. Present a structured plan that covers:
   - Which test files will be created or modified, and in which `TangemUITests/Tests/<Feature>/` folder
   - Which page objects are needed — new vs. extending existing under `TangemUITests/Screens/`
   - Which accessibility identifiers will be added, in which struct/enum in `Modules/TangemAccessibilityIdentifiers/`, and which SwiftUI views in the app must receive `.accessibilityIdentifier(...)`
   - Which mocks under `../tangem-api-mocks` need new mappings or scenarios
   - Which existing tests could be affected by mock changes (see §8)
5. Wait for the user to approve the plan via `ExitPlanMode`. Do not start implementation before approval.

Skip this only if the user has explicitly said "skip the planning phase" in this conversation.

## 2. Core principles

- Strictly apply SOLID.
- Use the Page Object pattern for every screen and reusable component.
- Make components reusable; separate responsibilities between classes.
- Read existing tests first — follow the established conventions, do not invent your own.
- Optimize for readability, maintainability, and reliability. Flaky tests are worse than no test.

## 3. XCUITest conventions

- Use modern XCUITest APIs (XCUIElement queries, predicates, etc.).
- **NEVER use `Thread.sleep()` or `sleep()`.** Use explicit waits with timeouts only.
- Prefer `waitAndAssertTrue(_:timeout:_:)` over `waitForExistence(timeout:)`.
- Use `NSPredicate` for complex element searches.
- Wrap each logical step in `XCTContext.runActivity` — perform assertions and return values inside the activity closure so Allure / Xcode reports correctly attribute the step.

## 4. Accessibility identifiers

All identifiers live in the `TangemAccessibilityIdentifiers` module (`Modules/TangemAccessibilityIdentifiers/`).

- Naming: `screenName_elementType_elementName` (e.g., `mainScreen_button_buy`). Hierarchical and meaningful.
- Group by screen: one struct/enum per screen file (e.g., `SendAccessibilityIdentifiers.swift`).
- **CRITICAL: apply every new identifier to the actual SwiftUI view** using `.accessibilityIdentifier(...)`. An identifier defined but not applied is a guaranteed test failure.
- **CRITICAL: in app code, ONLY add `.accessibilityIdentifier(...)`.** Do not change layout, view hierarchy, bindings, modifier chains, or wrappers. Do not remove or rewrite comments. Do not "tidy up" surrounding code. Layout regressions caused by UI-test work are a known pain point on this team — keep the diff to identifier additions only.

## 5. Page Object pattern

- One class per screen or reusable component, under `TangemUITests/Screens/<Feature>/`.
- Encapsulate element locators inside the page class — tests must not query `XCUIElement` directly.
- Methods return either another Page object (for navigation) or data.
- Use fluent interfaces (method chaining) where it improves readability.

## 6. File header

Every new UI test or page object file must start with:

```swift
//
//  FileName.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © YYYY Tangem AG. All rights reserved.
//
```

Resolve `<git user.name>` by running `git config user.name` once and reusing the value. Use today's date for `DD.MM.YYYY` and the current year for `YYYY`.

## 7. Test writing rules

- Use explicit waits with timeouts everywhere.
- Test method names describe the scenario in plain words, not abbreviations.
- DRY: extract shared setup into helpers, page objects, or `BaseTestCase` subclasses.
- Do NOT add `// MARK: -` comments in test files.
- Do NOT comment test classes — code must be self-documenting.
- **Comments MUST be a single short line.** No multi-line `///` blocks, no multi-sentence rationales, no "why we do X / what TestIT says / how the layout works" explanations. If a comment is needed at all, it is one sentence pointing at the non-obvious fact. Everything else belongs in the PR description or commit body.
- Private methods MUST be placed at the very end of the class.
- Never create README files.
- All committed test code is English-only (file content, identifiers, comments). Foreign-language strings used as test data / fixtures are the only exception.

## 8. API mocks — safety rules

Mocks live in `../tangem-api-mocks` (WireMock). They are shared across tests, so changes carry blast radius.

**Before changing any mock file:**

1. Search `TangemUITests/` for all tests referencing the `scenarioName` you're about to touch.
2. Inspect `BaseTestCase` subclasses for `ScenarioConfig` entries that depend on it.
3. Identify every test that uses the same `tangemApiType: .mock`, `expressApiType: .mock`, or `stakingApiType: .mock` and could be affected.

**Hard rules:**

- **Never remove or rename** existing scenario states (`Started`, `Empty`, `Unreachable`, …) used by other tests. Add a new state instead.
- **Never modify existing response files** under `__files/` referenced by other mappings. Create a new file with a descriptive name (e.g., `*-custom-scenario-response.json`) and point a new mapping at it.
- When adding new mappings to an endpoint that already has some, use `priority` carefully — a higher-priority mapping shadows existing ones and silently breaks tests.
- After mock changes, the user runs the impacted UI tests locally (do not invoke `fastlane ui_test` or `xcodebuild test` from this skill — the user runs tests themselves).

## 9. End-to-end workflow

After plan approval:

1. Re-read patterns: open neighbouring tests under `TangemUITests/Tests/<Feature>/`, existing page objects under `TangemUITests/Screens/<Feature>/`, and the relevant identifiers file under `Modules/TangemAccessibilityIdentifiers/`.
2. Check existing identifiers before adding new ones — reuse if a suitable one already exists.
3. Implement the page objects, identifiers, and tests.
4. Apply each new identifier to the actual SwiftUI view in app code with only `.accessibilityIdentifier(...)` — no other changes (§4).
5. If mocks were added or modified in `../tangem-api-mocks`, list the impacted tests so the user can run them locally (§8).
6. Verify the test target builds (use `BuildProject` Xcode MCP tool if available; otherwise tell the user how to build).
7. Do not run UI tests yourself. The user runs UI tests locally.

## 10. When to stop and ask the user

- Conflicting conventions in nearby files (which to follow?).
- Ambiguous element location (multiple matches, no obvious identifier).
- Scenario name collision in mocks (would touching it break other tests?).
- Any other situation where the right call is unclear. Use `AskUserQuestion` rather than guessing.
