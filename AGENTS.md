# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code), Microsoft Copilot and other agents when working with code in this repository.

## Project Overview

Tangem iOS is a cryptocurrency wallet app built with SwiftUI. The app supports hardware wallets (Tangem cards), mobile wallets, staking, token swaps (Express), Visa card integration, and WalletConnect.

The source code located in the `tangem-developments/tangem-app-ios` repository.

Requirements: iOS 16.4+, Xcode 16.4, Swift 5.10

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

Always fetch installed iOS simulators (using appropriate command line tools like `simctl`) and select the one with the most recent iOS version to build and run the project

### Testing
```bash
bundle exec fastlane test                                               # Unit tests (Production scheme)
bundle exec fastlane test_modules                                       # SPM module tests
bundle exec fastlane ui_test                                            # UI tests (Alpha scheme)
bundle exec fastlane ui_test only_testing:TangemUITests/TestClassName   # Single test class
```

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

Uses a property wrapper based DI system:
```swift
@Injected(\.someService) private var someService
```
Dependencies are registered via `InjectionKey` protocol in extensions of `InjectedValues`.

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

**Style Guide:** Follow [Google's Swift Style Guide](https://google.github.io/swift/)

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

## CI/CD

- **Danger** enforces linting and blocks PRs with compiler warnings/errors
- PRs over 500 LOC trigger size warnings
- Issue tracking: `IOS-*` links to Jira tasks

## Documentation

Always use Context7 MCP for fetching library/API documentation, code generation, or configuration steps.

## Miscellaneous

- DO NOT read, access or modify files at paths specified in the @.cursorignore file
- When adding new Swift or Objective-C files to the project itself (not to SPM modules, `./Modules/*`), always modify the project file (`TangemApp.xcodeproj/project.pbxproj`) accordingly
- Call `./bootstrap.sh` once in the beginning of current working session. It's absolutely required before starting you work on the project to install all dependencies, to perform codegen, etc
