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
    private lazy var segwitAddress = staticText(.segwitAddress)
    private lazy var closeButton = button(.closeButton)

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

    func readSegwitAddress() -> String {
        XCTContext.runActivity(named: "Read segwit Bitcoin address") { _ in
            waitAndAssertTrue(segwitAddress, "Segwit address should be displayed")
            return segwitAddress.label.replacingOccurrences(of: "\u{200B}", with: "")
        }
    }

    func close() -> TokenScreen {
        XCTContext.runActivity(named: "Close Receive sheet") { _ in
            closeButton.waitAndTap()
            return TokenScreen(app)
        }
    }
}

enum ReceiveTemplatesSheetElement: String, UIElement {
    case showQRCodeButton
    case segwitAddress
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .showQRCodeButton:
            return "Show QR code"
        case .segwitAddress:
            return ReceiveAccessibilityIdentifiers.segwitAddress
        case .closeButton:
            return CommonUIAccessibilityIdentifiers.closeButton
        }
    }
}
