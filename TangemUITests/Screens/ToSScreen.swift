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
    func acceptAgreement() -> StoriesScreen {
        XCTContext.runActivity(named: "Tap Accept Button") { _ in
            acceptButton.waitAndTap()
            return StoriesScreen(app)
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
