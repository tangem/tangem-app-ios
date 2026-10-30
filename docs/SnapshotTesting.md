# Snapshot tests

Snapshot tests compare prepared views against reviewed PNG references. They live in the `TangemSnapshotTests` target of `TangemApp.xcodeproj`, which is hosted by `Tangem.app`, so a test can snapshot any view of the application (`@testable import Tangem`) and of the SPM modules. `TangemSnapshotTestSupport` (a library product of `Modules`, linked only into the test target) provides `SnapshotScenario`, `SnapshotCanvas`, `SnapshotDevice`, the assertion helper, `SnapshotGrid` and the recording policy. It re-exports `SnapshotTesting`.

Snapshots are drawn with `drawHierarchyInKeyWindow`, from the host application's key window. This is what renders `ScrollView`/`List` content, UIKit views, blur, materials and Liquid Glass correctly; layer rendering without a host and `drawingGroup()` lose some of them.

## Rules

- Define one `<Feature>SnapshotScenario` enum per view. Each case is a scenario and `body` is its ready-to-render view. A `String`-backed enum gets its reference name from the raw value; an enum with associated values implements `snapshotName` and `allCases` itself.
- Keep the scenario enum nonisolated so `allCases` works with `@Test(arguments:)`. Mark only `body` and view-building helpers `@MainActor`.
- Declare the scenario's `canvases`: `[.component]` (default, ideal size) for components, `.screen(<device>)` for full screens, `.fixed(width:height:)` for a custom canvas. A screen usually needs `.screen(.regular)`; list `.compact` or `.large` as well only when the layout changes at that size.
- Cover right-to-left layout or another text size with a separate case that overrides `layoutDirection` or `dynamicTypeSize` (`.leftToRight` and `.large` by default), like `slotsRTL` in [BadgeSnapshotScenario](../TangemSnapshotTests/Sources/Badge/BadgeSnapshotScenario.swift). The case name keeps its references apart.
- Define one `<Feature>SnapshotTests` suite with one parameterized test that calls `assertSnapshots(of: scenario)`. Don't call the library's `assertSnapshot`: it stores references next to the test file, inside `Sources`, from where they are copied into the test bundle.
- Put test sources under `TangemSnapshotTests/Sources`, the target's synchronized folder. References are stored in `TangemSnapshotTests/__Snapshots__/<test file>/`, outside that folder, so they are never copied into the test bundle and new suites need no project changes. Adding or reordering cases does not rename existing references.
- Record references only through `bundle exec fastlane test_snapshots ... record:true`. Review image changes before accepting them; comparison runs must not write references.

## Views under test

A view is easy to snapshot when its data comes through `init` as plain values (a `struct` model with a fixed stub), its states (loading, empty, error, content) are explicit inputs, and nothing inside depends on the network, the current date, randomness or timers. Views that create their own dependencies, for example a `@StateObject` that loads video or a service resolved with `@Injected`, cannot be put into a fixed state and need refactoring first.

## Run and record

Run from the repository root:

```sh
bundle exec fastlane test_snapshots
bundle exec fastlane test_snapshots only_testing:TangemSnapshotTests/BadgeSnapshotTests
bundle exec fastlane test_snapshots only_testing:TangemSnapshotTests/BadgeSnapshotTests record:true
```

In Xcode, select the `TangemSnapshotTests` scheme and the simulator from `.ios-sim-runtime`. A recording run reports failures for newly written references; review the PNG changes, then run again without `record:true`.

Use the Xcode version in `.xcode-version` and the simulator in `.ios-sim-runtime` for recording and comparison; the simulator is the largest `SnapshotDevice`, so every canvas fits on its screen. The lane forwards `SNAPSHOT_TESTING_RECORD` through `TEST_RUNNER_SNAPSHOT_TESTING_RECORD`, using `all` for recording and `never` for comparison. It also forwards `CI` through `TEST_RUNNER_CI`, restores the previous environment on exit and explicitly rejects `record:true` on CI.

Suites use `.snapshots(record: .fromEnvironment)`: on CI it returns `.never` regardless of the recording variable; locally it parses that variable and falls back to `.never` when it is absent or invalid. The fallback is intentional because the library default, `.missing`, writes missing references.

The `TangemSnapshotTests` test plan sets the language to English, the region to the United States and `TZ=UTC`, so formatters that read `Locale.current` and `TimeZone.current` produce the same output on every machine. It also sets `TANGEM_SNAPSHOT_HOST=1`: in DEBUG builds the application then applies its UIKit appearance, skips service initialization and connects an empty window instead of the regular scene.

## Add a snapshot

Implement `SnapshotScenario` in `TangemSnapshotTests/Sources/<Feature>/`, next to the suite. Its `@MainActor @ViewBuilder body` switches over cases and returns ready views. Keep fixture data, factories and grid composition with the scenario, as in [BadgeSnapshotScenario](../TangemSnapshotTests/Sources/Badge/BadgeSnapshotScenario.swift). `SnapshotGrid<Data, Content>` arranges a random-access collection of cells; stacks and single views use ordinary SwiftUI.

```swift
import TangemSnapshotTestSupport
import Testing

@MainActor
@Suite(.serialized, .snapshots(record: .fromEnvironment))
struct BadgeSnapshotTests {
    @Test(arguments: BadgeSnapshotScenario.allCases)
    func badge(_ scenario: BadgeSnapshotScenario) {
        assertSnapshots(of: scenario)
    }
}
```

The library replaces non-word characters in file names with `-`. A `.component` or `.fixed` canvas produces `<name>.light.png` and `<name>.dark.png`; a `.screen(<device>)` canvas produces `<name>.<device>-<theme>.png`, for example `loaded.regular-dark.png`. The test function's name and argument order do not affect file names.

Every snapshot is drawn through the same key window, so nothing may run concurrently. `.serialized` orders the tests of one suite; the test plan disables parallelization for the whole target, which keeps different suites apart. Both are required.

## Canvases and devices

| Canvas | Size | Safe area | Scale |
|---|---|---|---|
| `.component` | ideal size of the view plus 8 pt padding | none | 3x |
| `.screen(<device>)` | the device's | the device's | the device's |
| `.fixed(width:height:)` | the given size | none | 3x |

| Device | Size | Safe area (top, bottom) | Scale |
|---|---|---|---|
| `compact` | 375 × 667 | 20, 0 | 2x |
| `regular` | 402 × 874 | 62, 34 | 3x |
| `large` | 440 × 956 | 62, 34 | 3x |

Device names describe size classes rather than models, so replacing a model in the set re-records references without renaming them. Each device is a library `ViewImageConfig`: `compact` is `.iPhone8`, while `regular` and `large` combine current sizes with the library's iPhone 13 and iPhone 13 Pro Max traits. A screen is laid out with `.device(config:)`. The host window keeps its own safe area, so the library receives the configuration with a zero safe area and the strategy applies the device's insets itself. The strategy also sets the content size category from `dynamicTypeSize`, overriding the `.medium` category of the library presets.

The background is `DesignSystem.Color.bgPrimary`; fixtures use `DesignSystem.Color` and `DesignSystem.Font`. Comparison thresholds are precision `1` and perceptual precision `0.98` for every canvas.

## Keep runs repeatable

The strategy disables SwiftUI transaction animations and also sets the SwiftUI locale to `en_US` and the time zone to UTC. Construct fresh view state for each scenario. Use fixed dates, IDs, balances, ordering, local images and prepared state. Inject stubs for services and clocks; avoid live requests, wall-clock time, timers and arbitrary sleeps.

Transaction settings do not freeze UIKit, Lottie or timeline animations. Pass a fixed time or progress into those views; existing unit or UI tests cover transitions and asynchronous behavior.

Repeat selected tests before treating a scenario as stable. Investigate unexpected differences before recording. AI agents follow the same workflow: never lower precision or replace references merely to make an unexplained failure pass. Inspect actual and difference images in Xcode test results or the result bundle under `test_output/snapshots`.
