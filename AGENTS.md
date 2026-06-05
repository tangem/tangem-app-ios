# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code), Microsoft Copilot and other agents when working with code in this repository.

## Prompt check (perform it for ALL user prompts)

Always check all user prompts for grammar, punctuation, and styling issues and mistakes. If there are any such issues/mistakes, you MUST ALWAYS start your response with a fixed version of the user prompt in bold with highlighted wrong parts, like this example:

```text
User: i has a question
LLM: Fixed prompt: **`I have` a question.**
LLM: To answer your question...
```

## Project Overview

Tangem iOS is a cryptocurrency wallet app built with SwiftUI. The app supports hardware wallets (Tangem cards), mobile wallets, staking, token swaps (Express), Visa card integration, and WalletConnect.

The source code located in the `tangem-developments/tangem-app-ios` repository.

Requirements: iOS 16.4+, Xcode 16.4, Swift 5.10

## Workflow Conventions

Every change starts with a Jira ticket whose key flows through the rest of the workflow, and every PR goes through a self-review before being opened:

- **Every change carries a Jira ticket key.** Branch names, commit subjects, and PR titles all include an `IOS-NNNNN` prefix. Before starting, decide whether the work belongs on an existing ticket or needs a new one — if it isn't obvious, ask. Either way, before any code is touched the ticket must be: assigned to you, in the active sprint, and have both required custom fields populated. The rule applies regardless of whether the ticket is fresh or reused — fill in anything that's missing on a reused one (it usually is).
  - **Story Points (`customfield_10025`)** — default to `3` unless context clearly suggests otherwise (trivial = 1; clear hotfix or multi-day work = 5+).
  - **QA Notes (`customfield_11232`)** — per-scenario test plan using the team's template (Preconditions / Steps / Expected result). For changes with zero runtime impact (pure docs/comments, dead-code removal) the entire field can be the team's standard one-line "no QA needed" shorthand — don't fabricate fake scenarios; QA reads the field and noise wastes their time. Refactors, renames, or anything that produces a different binary still need real QA scenarios.

  See [External Systems → Jira](#jira) for cloudId, field IDs, and the ADF caveat.
- **Branch name:** `IOS-NNNNN_short_description` in snake_case (e.g. `[REDACTED_INFO]_crashfixes`).
- **When asked to create a branch, give it its own remote immediately.** `git checkout -b <branch> origin/develop` leaves `<branch>` tracking `origin/develop`, so an IDE "Push" writes straight to `develop`. Right after creating it run `git push -u origin <branch>` (or `git branch --unset-upstream` if not pushing yet). Never push to `develop`/`master` directly.
- **Commit message subject:** `IOS-NNNNN Short description`. Body explains the why, not the what — the diff already shows the what.
- **Move the issue to `In Progress`** the moment you create the branch and start work. Use `getTransitionsForJiraIssue` to find the right transition id, then `transitionJiraIssue`. Don't leave a ticket in `To Do` while a branch with commits exists — sprint metrics and standups read these states.
- **Self-review before opening the PR.** Once the branch builds and tests pass, do an independent review of the diff as if it were someone else's code: either read `git diff <base>..HEAD` end-to-end with fresh eyes, or delegate to a sub-agent (e.g. Claude Code's `Agent` tool with a skeptical-reviewer prompt; equivalent in other agent harnesses). Apply any meaningful feedback as additional commits before opening the PR — the goal is to spend the human reviewer's attention on judgment calls, not on things you would have caught yourself.
- **PR title:** identical to the commit subject. The PR body MUST include `[IOS-NNNNN](https://tangem.atlassian.net/browse/IOS-NNNNN)` on its own line so the Atlassian/GitHub integration links the PR back to the ticket. Opening the PR generally moves the issue to `Review` automatically.
- **PR description style.** Convey the essence — the problem and the approach — in a few plain sentences. Don't walk through the changes file by file or restate the diff; it speaks for itself. Don't tell reviewers what to look at, flag the "riskiest" part, or ask for a second opinion — they decide where to focus. Cut filler and hedging. Write idiomatically in the language of the team conversation — no runglish or word-for-word calques. Keep verification steps only when genuinely useful. PR descriptions live on GitHub (not in the repo).
- All commits require a valid GPG signature (see Miscellaneous).

## Build & Development Commands

### Initial Setup
```bash
./bootstrap.sh                    # Full setup (Ruby, Mint deps, SwiftFormat, SwiftGen)
./bootstrap.sh --skip-ruby        # Skip Ruby installation
./bootstrap.sh --skip-mint        # Skip Mint dependencies
```

### Building
Open `TangemApp.xcodeproj` in Xcode. There are three main schemes:
- **Tangem** - Production
- **Tangem Beta** - Beta testing
- **Tangem Alpha** - Internal testing

Always prefer Xcode MCP for building and testing. If Xcode MCP is not available or not working - build the project using appropriate cli tools like `xcodebuild`. In this case, always fetch installed iOS simulators first (using appropriate cli tools like `simctl`) and select the one with the most recent iOS version to build and run the project

### Testing
```bash
bundle exec fastlane test                                               # Unit tests (Production scheme)
bundle exec fastlane test_modules                                       # SPM module tests
bundle exec fastlane ui_test                                            # UI tests (Alpha scheme)
bundle exec fastlane ui_test only_testing:TangemUITests/TestClassName   # Single test class
```

For a single SPM module test class without running the full module suite (e.g. `TangemFoundationTests/MyTests`):
```bash
cd Modules && xcodebuild test \
    -scheme TangemModules \
    -destination 'platform=iOS Simulator,id=<udid>' \
    -only-testing:TangemFoundationTests/MyTests \
    -disableAutomaticPackageResolution \
    -onlyUsePackageVersionsFromResolvedFile
```
Note: plain `swift test` from `Modules/` fails due to macOS deployment-target conflicts with iOS-only deps. Module test targets use **Swift Testing** (`@Suite`/`@Test`/`#expect`), not XCTest — see `Modules/TangemFoundationTests/PublisherAsyncTests.swift` for race-test patterns (`nonisolated(unsafe)` captures, `@preconcurrency import Combine`). Add `-enableThreadSanitizer YES` for race investigations.

### Code Formatting
SwiftFormat runs automatically during bootstrap and is enforced by CI (Dangerfile). Manual run:
```bash
mint run swiftformat@0.55.5 . --config .swiftformat
```

### Code Generation
SwiftGen generates type-safe assets and localization:
```bash
mint run swiftgen@6.6.3 config run --config swiftgen.yml
```

## Architecture

### Module Structure

The project uses a hybrid structure with both Xcode targets and Swift Package Manager modules:

**Main Xcode Targets:**
- `Tangem/` - Main app code (Features, Domain, UI)
- `BlockchainSdk/` - Blockchain integrations
- `TangemExpress/` - Token swap functionality
- `TangemStaking/` - Staking functionality
- `TangemVisa/` - Visa card integration

**SPM Modules (in `Modules/`):**
- `TangemFoundation` - Core utilities
- `TangemLogger` - Logging infrastructure
- `TangemNetworkUtils` - Networking (Moya/Alamofire wrappers)
- `TangemUI` - Shared SwiftUI components
- `TangemUIUtils` - UI utilities
- `TangemAssets` - Images, colors, Lottie animations
- `TangemLocalization` - Localized strings
- `TangemMobileWalletSdk` - Mobile wallet cryptography
- `TangemMacro` - Swift macros
- `TangemAccessibilityIdentifiers` - UI testing identifiers
- `TangemAccounts` - Accounts management
- `TangemStories` - Stories feature
- `TangemNFT` - NFT functionality

### Navigation Pattern

The app uses a Coordinator pattern for navigation. Each feature has:
- `*Coordinator.swift` - Navigation logic, conforms to `CoordinatorObject`
- `*CoordinatorView.swift` - SwiftUI view wrapper

```swift
protocol CoordinatorObject: ObservableObject, Identifiable {
    associatedtype InputOptions
    associatedtype OutputOptions
    var dismissAction: Action<OutputOptions> { get }
    var popToRootAction: Action<PopToRootOptions> { get }
    func start(with options: InputOptions)
}
```

### Dependency Injection

Uses a property wrapper based DI system for singletons:
```swift
@Injected(\.someService) private var someService
```
Singleton dependencies are registered via `InjectionKey` protocol in extensions of `InjectedValues`.
Normal dependencies are injected using plain Swift constructors.

### Feature Organization

Features in `Tangem/Features/` follow a consistent structure:
- Each feature folder contains Coordinator, Views, ViewModels, and related types
- ViewModels are typically `ObservableObject` classes
- Views use SwiftUI

### Domain Layer

Located in `Tangem/Domain/`:
- `Accounts/` - Account management
- `BlockchainSdk/` - Blockchain domain types
- `TangemSdk/` - Tangem SDK integration
- `UserWalletModel/` - Wallet state management
- `WalletModel/` - Individual wallet logic
- `TokenItem/` - Token representation
- `Fee/` - Transaction fee handling

## Key Technologies

- **Swift 5.10** (transitioning to Swift 6)
- **iOS 16.4+**
- **Xcode 16.4**
- **SwiftUI** for UI
- **Combine** for reactive programming
- **SPM** for module organization
- **Moya/Alamofire** for networking
- **Kingfisher** for image loading
- **tangem-sdk-ios** for hardware wallet communication

## Build Configurations

SPM modules support conditional compilation via environment variables:
- `SWIFT_PACKAGE_BUILD_FOR_ALPHA` - Alpha build flags
- `SWIFT_PACKAGE_BUILD_FOR_BETA` - Beta build flags

This enables `ALPHA`, `BETA`, and `ALPHA_OR_BETA` compile-time flags.

## Fastlane Lanes

Key lanes defined in `fastlane/Fastfile`:
- `test` - Run unit tests
- `test_modules` - Run SPM module tests
- `ui_test` - Run UI tests
- `build_Alpha` - Build Alpha for Firebase
- `build_Beta` - Build Beta for Firebase
- `build_RC` - Build Release Candidate for TestFlight
- `update_translations` - Fetch translations from Lokalise

## Code Style

**English only in committed content.** Code, comments, identifiers, commit messages, and PR titles (which mirror commit subjects) are English. Foreign-language product strings used as test data or fixtures are an exception, but commentary about them stays English. Non-versioned surfaces — PR descriptions, Jira fields and comments, Slack, Confluence — aren't constrained and typically follow the language of the current conversation. When that language isn't English, write the way a native speaker of it would: express each technical idea in the target language's own words rather than transliterating the English term, so the text reads as natural prose and not a calque. Only genuine code identifiers and proper nouns stay in English.

**Style Guide:** Follow [Google's Swift Style Guide](https://google.github.io/swift/)

**No redundant comments.** Don't add comments that merely restate what the code or the language already conveys — e.g. annotating a `static let` with "Resolved once" / "Cached / fixed for the process lifetime", or a `private` member with "Used internally". A comment must explain something the reader can't get from the declaration itself: a non-obvious *why*, a constraint, a gotcha, or intent that isn't visible in the code. When in doubt, leave it out — the diff and the type signatures already document the *what*.

**SwiftUI Previews:** Must be wrapped in `#if DEBUG`/`#endif` and marked with `// MARK: - Previews`:
```swift
// MARK: - Previews

#if DEBUG
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        MyView()
    }
}
#endif // DEBUG
```

**Generated Files:** Never modify files in:
- `Modules/TangemAssets/Generated/`
- `Modules/TangemLocalization/Generated/`

**Thread-safe mutable state:** Prefer `OSAllocatedUnfairLock(initialState:)` over hand-rolled `NSLock` + `@unchecked Sendable` for guarding shared state in tests, stubs, and utilities. The `withLock { state in ... }` API encapsulates state ownership and removes the need for the unchecked annotation:

```swift
import TangemFoundation

private let state = OSAllocatedUnfairLock(initialState: State())

func append(_ event: Event) {
    state.withLock { $0.events.append(event) }
}

var events: [Event] {
    state.withLock { $0.events }
}
```

The type is re-exported via `Modules/TangemFoundation/Extensions/Foundation/OSAllocatedUnfairLock+.swift` — `import TangemFoundation` to get it.

## CI/CD

- **Danger** enforces linting and blocks PRs with compiler warnings/errors
- PRs over 500 LOC trigger size warnings
- Issue tracking: `IOS-*` links to Jira tasks

## External Systems

### Firebase Crashlytics

- **iOS app ID:** `1:721920782444:ios:33c2eaa02d871fc63f2849` (Tangem iOS Release, bundle `com.tangem.Tangem`). Required for every `mcp__firebase__crashlytics_*` call.
- **Console URL template for an issue:** `https://console.firebase.google.com/v1/appid/project/tangemapp/crashlytics/app/1:721920782444:ios:33c2eaa02d871fc63f2849/issues/{issueId}`. Use this when linking crashes from Jira/PRs instead of constructing URLs from event resource names.
- **Querying a specific build:** call `crashlytics_get_report` with `report=topIssues` and `versionDisplayNames=["5.X (NNNN)"]`. Display name format is `version (build)` — get exact strings via the `topVersions` report first.
- **Tooling caveat:** `crashlytics_list_events` with `pageSize >= 5` for a busy issue exceeds the MCP token limit and writes the result to a temp file. Same for `crashlytics_batch_get_events` with 10+ events. Delegate trace analysis to a sub-agent that reads the file in chunks.
- After a fix is merged, mark closed issues `CLOSED` via `crashlytics_update_issue`. Skip vendor-SDK crashes (e.g. Sumsub) — those need vendor tickets.

### Jira

- **Cloud ID:** `d018e0a4-7934-4a07-a61b-3533039acdfa` (`tangem.atlassian.net`).
- **iOS project key:** `IOS`. Default issue type `Task` (id `10002`). Active sprint id is on `customfield_10021` (read it off any open ticket on board id `12`).
- **`customfield_11232` — `QA Notes`** is the field manual QA reads. Use the team's per-scenario template (Preconditions / Steps / Expected result), not the description. Discover other field IDs via `getJiraIssueTypeMetaWithFields(cloudId, projectIdOrKey="IOS", issueTypeId="10002")`.
- **Markdown vs ADF:**
  - `editJiraIssue` accepts a markdown string for the built-in `description` field (server-side conversion).
  - `createJiraIssue` rejects markdown for `description` — pass an Atlassian Document Format JSON doc instead.
  - Any custom textarea field (e.g. `customfield_11232`) on **either** tool always requires ADF `{"type": "doc", "version": 1, "content": [...]}`.
  - Build ADF programmatically (a small Python helper for `paragraph`/`heading`/`orderedList`/`text`+`marks` keeps the JSON readable).
- **Assignee on create:** `assignee_accountId` shorthand is silently dropped by `createJiraIssue`. Always follow up with `editJiraIssue` `{"assignee": {"accountId": "..."}}` and read back the issue to verify.

## Documentation

For Apple platform documentation (iOS/macOS APIs, frameworks, WWDC content) use the sosumi MCP. For all other library/API documentation, code generation, or configuration steps use Context7 MCP.

## Xcode MCP Tools

This project has Xcode MCP integration available. **Prefer Xcode MCP tools over shell commands when working with Xcode projects** as they provide direct integration with the IDE.

### File Operations

| Tool | Description | Use Case |
|------|-------------|----------|
| `XcodeRead` | Read files from the project | Reading source files through Xcode's file system |
| `XcodeWrite` | Write files to the project | Creating new files in the project |
| `XcodeUpdate` | Edit files with str_replace-style patches | Modifying existing files |
| `XcodeGlob` | Find files by pattern | Searching for files matching a glob pattern |
| `XcodeGrep` | Search file contents | Finding code patterns across the project |
| `XcodeLS` | List directory contents | Exploring project structure |
| `XcodeMakeDir` | Create directories | Adding new folders to the project |
| `XcodeRM` | Remove files | Deleting files from the project |
| `XcodeMV` | Move/rename files | Reorganizing project files |

### Building & Testing

| Tool | Description | Use Case |
|------|-------------|----------|
| `BuildProject` | Build the Xcode project | Compiling the app (prefer over `xcodebuild` CLI) |
| `GetBuildLog` | Get build output | Retrieving build results and errors |
| `RunAllTests` | Run all tests | Executing the full test suite |
| `RunSomeTests` | Run specific tests | Running targeted test classes/methods |
| `GetTestList` | List available tests | Discovering available test targets |

### Diagnostics & Issues

| Tool | Description | Use Case |
|------|-------------|----------|
| `XcodeListNavigatorIssues` | Get Xcode issues/errors | Retrieving all project warnings and errors |
| `XcodeRefreshCodeIssuesInFile` | Get live diagnostics | Getting real-time code issues for a specific file |

### Development Utilities

| Tool | Description | Use Case |
|------|-------------|----------|
| `ExecuteSnippet` | Run code in a REPL-like environment | Testing Swift code snippets interactively |
| `RenderPreview` | Render SwiftUI previews as images | Generating preview screenshots |
| `DocumentationSearch` | Search Apple docs and WWDC videos | Finding official Apple documentation |
| `XcodeListWindows` | List open Xcode windows | Getting info about open Xcode windows |

### Usage Guidelines

1. **Building:** Use `BuildProject` instead of `xcodebuild` CLI for better integration
2. **Diagnostics:** Use `XcodeListNavigatorIssues` to get all project issues before attempting fixes
3. **Testing:** Use `RunSomeTests` for targeted test runs instead of full suite runs
4. **Previews:** Use `RenderPreview` to validate SwiftUI views without running the simulator
5. **Documentation:** Use `DocumentationSearch` to find Apple API documentation and WWDC content

## Miscellaneous

- DO NOT read, access or modify files at paths specified in the @.cursorignore file
- DO NOT build anything unless you're explicitly asked to do so
- When adding new Swift or Objective-C files to the project itself (not to SPM modules, `./Modules/*`), always modify the project file (`TangemApp.xcodeproj/project.pbxproj`) accordingly. Always prefer to use tools from Xcode MCP for modifying the project file.
- Call `./bootstrap.sh` once in the beginning of current working session. It's absolutely required before starting you work on the project to install all dependencies, to perform codegen, etc
- All commits in this repository must always have a valid GPG signature
