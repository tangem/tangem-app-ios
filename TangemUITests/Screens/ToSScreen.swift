//
//  ToSScreen.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class ToSScreen: ScreenBase<ToSPageUIElement> {
    private lazy var acceptButton = button(.acceptButton)

    @discardableResult
    func acceptAgreement() -> CreateWalletSelectorScreen {
        XCTContext.runActivity(named: "Tap Accept Button") { _ in
            acceptButton.waitAndTap()
            return CreateWalletSelectorScreen(app)
        }
    }

    func waitForToSAcceptButton() {
        XCTContext.runActivity(named: "Wait for ToS accept button") { _ in
            waitAndAssertTrue(acceptButton)
        }
    }
}

enum ToSPageUIElement: String, UIElement {
    case acceptButton

    var accessibilityIdentifier: String {
        switch self {
        case .acceptButton:
            TOSAccessibilityIdentifiers.acceptButton
        }
    }
}
