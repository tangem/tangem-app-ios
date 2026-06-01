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
    private lazy var errorToast = staticText(.errorToast)

    @discardableResult
    func waitForQRScannerScreenToBeVisible() -> Self {
        XCTContext.runActivity(named: "Validate QR scan screen") { _ in
            waitAndAssertTrue(pasteButton, "Paste button should be visible")
            XCTAssertTrue(pasteButton.isHittable, "Paste button should be hittable")
            return self
        }
    }

    @discardableResult
    func tapPasteButton() -> WalletConnectSheet {
        XCTContext.runActivity(named: "Tap paste button") { _ in
            pasteButton.waitAndTap()
            return WalletConnectSheet(app)
        }
    }

    @discardableResult
    func pasteAndExpectError() -> Self {
        XCTContext.runActivity(named: "Tap paste, expect error toast") { _ in
            pasteButton.waitAndTap()
            waitAndAssertTrue(errorToast, timeout: .conditional, "Error toast should appear")
            return self
        }
    }

    @discardableResult
    func waitForErrorToastToDisappear() -> Self {
        XCTContext.runActivity(named: "Wait for error toast to auto-dismiss") { _ in
            XCTAssertTrue(
                errorToast.waitForState(state: .doesntExist, for: .conditional),
                "Error toast should auto-dismiss"
            )
            return self
        }
    }

    @discardableResult
    func assertConnectionSheetIsNotVisible() -> Self {
        XCTContext.runActivity(named: "Assert WC connection sheet is not visible") { _ in
            let sheetHeader = app.staticTexts[WalletConnectAccessibilityIdentifiers.headerTitle]
            XCTAssertFalse(
                sheetHeader.waitForExistence(timeout: .quick),
                "WalletConnect connection sheet must NOT appear for invalid URI"
            )
            return self
        }
    }
}

enum WalletConnectQRScanScreenElement: UIElement {
    case pasteButton
    case errorToast

    var accessibilityIdentifier: String {
        switch self {
        case .pasteButton:
            return WalletConnectAccessibilityIdentifiers.pasteButton
        case .errorToast:
            return WalletConnectAccessibilityIdentifiers.errorToast
        }
    }
}
