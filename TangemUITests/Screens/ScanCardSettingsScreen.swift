//
//  ScanCardSettingsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class ScanCardSettingsScreen: ScreenBase<ScanCardSettingsScreenElement> {
    private lazy var scanCardButton = button(.scanCardButton)

    func scanCard() -> DeviceSettingsScreen {
        XCTContext.runActivity(named: "Scan card for device settings") { _ in
            scanCardButton.waitAndTap()
            return DeviceSettingsScreen(app)
        }
    }

    @discardableResult
    func scanMockWallet(name: CardMockAccessibilityIdentifiers) -> DeviceSettingsScreen {
        XCTContext.runActivity(named: "Scan Mock Wallet: \(name)") { _ in
            scanCardButton.waitAndTap()
            let walletButton = app.buttons[name.rawValue].firstMatch
            if !walletButton.isHittable {
                app.swipeUp()
            }
            walletButton.waitAndTap()
            return DeviceSettingsScreen(app)
        }
    }

    func validateScreenElements() -> Self {
        XCTContext.runActivity(named: "Validate scan card settings screen elements") { _ in
            XCTAssertTrue(scanCardButton.waitForExistence(timeout: .robustUIUpdate), "Scan card button should exist")
            return self
        }
    }
}

enum ScanCardSettingsScreenElement: String, UIElement {
    case scanCardButton

    var accessibilityIdentifier: String {
        switch self {
        case .scanCardButton:
            return "Scan card or ring"
        }
    }
}
