//
//  CreateWalletSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class CreateWalletSelectorScreen: ScreenBase<CreateWalletSelectorScreenElement> {
    private lazy var createWalletButton = button(.createWalletButton)
    private lazy var existingWalletButton = button(.existingWalletButton)

    @discardableResult
    func scanMockWallet(name: CardMockAccessibilityIdentifiers) -> MainScreen {
        XCTContext.runActivity(named: "Scan Mock Wallet: \(name)") { _ in
            openScanMenu()

            selectWalletFromList(name: name)

            // For Twin cards, check if onboarding screen appears and handle it
            if name == .twin {
                return handleTwinOnboarding()
            }

            return MainScreen(app)
        }
    }

    @discardableResult
    func selectWalletFromList(name: CardMockAccessibilityIdentifiers) -> Self {
        XCTContext.runActivity(named: "Select mock wallet '\(name.rawValue)' from the list") { _ in
            let walletButton = app.buttons[name.rawValue].firstMatch
            scrollActionSheetToElement(walletButton)
            walletButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func openScanMenu() -> Self {
        XCTContext.runActivity(named: "Open scan alert") { _ in
            tapExistingWallet()
            tapActionSheetRow(.hardwareRow)
            return self
        }
    }

    @discardableResult
    func cancelScan() -> Self {
        XCTContext.runActivity(named: "Close scan alert") { _ in
            app.buttons["Cancel"].waitAndTapWithScroll()
            return self
        }
    }

    @discardableResult
    func importMobileWallet() -> SeedPhraseImportScreen {
        XCTContext.runActivity(named: "Import mobile wallet via recovery phrase") { _ in
            tapExistingWallet()
            tapActionSheetRow(.importRow)
            return WelcomeImportSheetScreen(app).tapRecoveryPhrase()
        }
    }

    @discardableResult
    func createMobileWallet() -> MainScreen {
        XCTContext.runActivity(named: "Create mobile wallet") { _ in
            createWalletButton.waitForStableFrame()
            createWalletButton.waitAndTap()
            tapActionSheetRow(.mobileRow)
            return MainScreen(app)
        }
    }

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for create wallet selector screen") { _ in
            waitAndAssertTrue(createWalletButton, "Create wallet button should be displayed")
            return self
        }
    }

    private func tapExistingWallet() {
        existingWalletButton.waitForStableFrame()
        existingWalletButton.waitAndTap()
    }

    /// The sheet rows collapse their children into a single element, so neither the type nor the first match is guaranteed.
    private func tapActionSheetRow(_ element: CreateWalletSelectorScreenElement) {
        let rows = app.descendants(matching: .any).matching(identifier: element.accessibilityIdentifier)

        guard let row = rows.firstHittableElement() else {
            XCTFail("Action sheet row \(element.accessibilityIdentifier) should be hittable")
            return
        }

        row.tap()
    }

    private func handleTwinOnboarding() -> MainScreen {
        XCTContext.runActivity(named: "Handle Twin onboarding screen") { _ in
            let onboardingScreen = TwinOnboardingScreen(app)

            let titleText = app.staticTexts["One wallet. Two cards."]
            if titleText.waitForExistence(timeout: .conditional) {
                return onboardingScreen
                    .validateScreen()
                    .tapContinue()
            } else {
                return MainScreen(app)
            }
        }
    }
}

enum CreateWalletSelectorScreenElement: String, UIElement {
    case createWalletButton
    case existingWalletButton
    case hardwareRow
    case mobileRow
    case importRow

    var accessibilityIdentifier: String {
        switch self {
        case .createWalletButton:
            WelcomeAccessibilityIdentifiers.createWalletButton
        case .existingWalletButton:
            WelcomeAccessibilityIdentifiers.existingWalletButton
        case .hardwareRow:
            WelcomeAccessibilityIdentifiers.actionSheetHardwareRow
        case .mobileRow:
            WelcomeAccessibilityIdentifiers.actionSheetMobileRow
        case .importRow:
            WelcomeAccessibilityIdentifiers.actionSheetImportRow
        }
    }
}
