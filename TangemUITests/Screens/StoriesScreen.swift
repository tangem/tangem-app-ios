
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
            // Wait for scan button with extended timeout since it's the first screen
            guard scanButton.waitForExistence(timeout: .criticalUIOperation) else {
                XCTFail("Initial scan button not found")
                return MainScreen(app)
            }

            // Ensure the button is hittable before tapping
            guard scanButton.waitForState(state: .hittable, for: .criticalUIOperation) else {
                XCTFail("Scan button exists but not hittable. Frame: \(scanButton.frame)")
                return MainScreen(app)
            }

            // Tap the scan button
            scanButton.tap()

            // Wait for mock wallet button and tap it
            let walletButton = app.buttons[name.rawValue]
            guard walletButton.waitForExistence(timeout: .criticalUIOperation) else {
                let availableButtons = app.buttons.allElementsBoundByIndex.map { $0.identifier }
                XCTFail("Mock wallet button '\(name.rawValue)' not found. Available buttons: \(availableButtons)")
                return MainScreen(app)
            }

            guard walletButton.waitForState(state: .hittable, for: .criticalUIOperation) else {
                XCTFail("Mock wallet button '\(name.rawValue)' exists but not hittable. Frame: \(walletButton.frame)")
                return MainScreen(app)
            }

            walletButton.tap()

            return MainScreen(app)
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
