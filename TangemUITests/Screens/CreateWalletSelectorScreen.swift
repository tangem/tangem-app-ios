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
    private lazy var scanButton = button(.scanButton)
    private lazy var tosAcceptButton = button(.tosAcceptButton)
    private lazy var getStartedButton = button(.getStartedButton)
    private lazy var startWithMobileWalletButton = button(.startWithMobileWalletButton)

    @discardableResult
    func scanMockWallet(name: CardMockAccessibilityIdentifiers) -> MainScreen {
        XCTContext.runActivity(named: "Scan Mock Wallet: \(name)") { _ in
            getStartedButton.waitAndTap()
            scanButton.waitAndTap()

            selectWalletFromList(name: name)

            // For Twin cards, check if onboarding screen appears and handle it
            if name == .twin {
                return handleTwinOnboarding()
            }

            return MainScreen(app)
        }
    }

    func selectWalletFromList(name: CardMockAccessibilityIdentifiers) {
        // Find the mock wallet button in the alert
        let walletButton = app.buttons[name.rawValue]

        if !walletButton.isHittable {
            app.swipeUp()
        }

        guard walletButton.waitForExistence(timeout: .robustUIUpdate) else {
            let availableButtons = app.buttons.allElementsBoundByIndex.map { $0.identifier }
            XCTFail(
                "Mock wallet button '\(name.rawValue)' not found in alert. Available buttons: \(availableButtons)"
            )
            return
        }

        guard walletButton.waitForState(state: .hittable) else {
            XCTFail("Mock wallet button '\(name.rawValue)' exists but is not hittable")
            return
        }

        walletButton.tap()
    }

    @discardableResult
    func acceptToSIfNeeded() -> Self {
        XCTContext.runActivity(named: "Accept ToS if needed") { _ in
            if tosAcceptButton.waitForExistence(timeout: .conditional) {
                tosAcceptButton.tap()
            }
            return self
        }
    }

    @discardableResult
    func allowPushNotificationsIfNeeded() -> Self {
        XCTContext.runActivity(named: "Accept ToS if needed") { _ in
            if app.buttons["Allow"].waitForExistence(timeout: .conditional) {
                app.buttons["Allow"].tap()
            }
            return self
        }
    }

    func openScanMenu() -> Self {
        XCTContext.runActivity(named: "Open scan alert") { _ in
            scanButton.waitAndTap()
            return self
        }
    }

    func skipStories() -> Self {
        XCTContext.runActivity(named: "Skip stories screen") { _ in
            getStartedButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func cancelScan() -> Self {
        XCTContext.runActivity(named: "Close scan alert") { _ in
            app.buttons["Cancel"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func startWithMobileWallet() -> MobileCreateWalletScreen {
        XCTContext.runActivity(named: "Open mobile wallet creation") { _ in
            startWithMobileWalletButton.waitAndTap()
            return MobileCreateWalletScreen(app)
        }
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
    case scanButton
    case tosAcceptButton
    case getStartedButton
    case startWithMobileWalletButton

    var accessibilityIdentifier: String {
        switch self {
        case .scanButton:
            StoriesAccessibilityIdentifiers.scanButton
        case .tosAcceptButton:
            TOSAccessibilityIdentifiers.acceptButton
        case .getStartedButton:
            StoriesAccessibilityIdentifiers.getStartedButton
        case .startWithMobileWalletButton:
            OnboardingAccessibilityIdentifiers.mobileWalletButton
        }
    }
}
