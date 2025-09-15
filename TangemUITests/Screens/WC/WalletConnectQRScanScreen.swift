//
//  WalletConnectQRScanScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class WalletConnectQRScanScreen: ScreenBase<WalletConnectQRScanScreenElement> {
    private lazy var pasteButton = button(.pasteButton)

    @discardableResult
    func waitForQRScannerScreenToBeVisible() -> Self {
        XCTContext.runActivity(named: "Validate QR scan screen") { _ in
            waitAndAssertTrue(pasteButton, "Paste button should be visible")
            XCTAssertTrue(pasteButton.isHittable, "Paste button should be hittable")
            return self
        }
    }

    func tapPasteButton() -> WalletConnectSheet {
        XCTContext.runActivity(named: "Tap paste button") { _ in
            pasteButton.waitAndTap()
            return WalletConnectSheet(app)
        }
    }
}

enum WalletConnectQRScanScreenElement: UIElement {
    case pasteButton

    var accessibilityIdentifier: String {
        switch self {
        case .pasteButton:
            return WalletConnectAccessibilityIdentifiers.pasteButton
        }
    }
}
