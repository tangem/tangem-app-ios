//
//  ReceiveTemplatesSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers
import Foundation

final class ReceiveTemplatesSheet: ScreenBase<ReceiveTemplatesSheetElement> {
    private lazy var showQRCodeButton = button(.showQRCodeButton)

    @discardableResult
    func validateShowQRCodeButtonDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate Show QR code button is displayed") { _ in
            waitAndAssertTrue(showQRCodeButton, "Show QR code button should be displayed")
        }
        return self
    }

    func tapShowQRCode() -> ReceiveQRCodeSheet {
        XCTContext.runActivity(named: "Tap Show QR code button") { _ in
            showQRCodeButton.waitAndTap()
            return ReceiveQRCodeSheet(app)
        }
    }
}

enum ReceiveTemplatesSheetElement: String, UIElement {
    case showQRCodeButton

    var accessibilityIdentifier: String {
        switch self {
        case .showQRCodeButton:
            return "Show QR code"
        }
    }
}
