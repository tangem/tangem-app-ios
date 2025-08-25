
//
//  StoriesScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class StoriesScreen: ScreenBase<StoriesScreenElement> {
    private lazy var scanButton = button(.scanButton)

    @discardableResult
    func scanMockWallet(name: CardMockAccessibilityIdentifiers) -> MainScreen {
        XCTContext.runActivity(named: "Scan Mock Wallet: \(name)") { _ in
            // Wait for scan button with extended timeout
            guard scanButton.waitForExistence(timeout: .robustUIUpdate) else {
                XCTFail("Initial scan button not found")
                return MainScreen(app)
            }

            // Tap the scan button directly after existence check
            Thread.sleep(forTimeInterval: 0.5)
            scanButton.tap()

            // Find the mock wallet button in the alert
            let walletButton = app.buttons[name.rawValue]

            if !walletButton.isHittable {
                app.swipeUp()
            }

            guard walletButton.waitForExistence(timeout: .robustUIUpdate) else {
                let availableButtons = app.buttons.allElementsBoundByIndex.map { $0.identifier }
                XCTFail("Mock wallet button '\(name.rawValue)' not found in alert. Available buttons: \(availableButtons)")
                return MainScreen(app)
            }

            guard walletButton.waitForState(state: .hittable) else {
                XCTFail("Mock wallet button '\(name.rawValue)' exists but is not hittable")
                return MainScreen(app)
            }

            walletButton.tap()

            // For Twin cards, check if onboarding screen appears and handle it
            if name == .twin {
                return handleTwinOnboarding()
            }

            return MainScreen(app)
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

enum StoriesScreenElement: String, UIElement {
    case scanButton

    var accessibilityIdentifier: String {
        switch self {
        case .scanButton:
            StoriesAccessibilityIdentifiers.scanButton
        }
    }
}
