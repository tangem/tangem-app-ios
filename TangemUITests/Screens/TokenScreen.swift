//
//  TokenScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TokenScreen: ScreenBase<TokenScreenElement> {
    enum TokenAction: String {
        case buy = "Buy"
    }

    private lazy var moreButton = otherElement(.moreButton)
    private lazy var hideTokenButton = button(.hideTokenButton)
    private lazy var actionButtons = otherElement(.tokenActionButtons)

    func hideToken(name: String) -> MainScreen {
        moreButton.waitAndTap()
        hideTokenButton.waitAndTap()
        app.alerts["Hide \(name)"].buttons["Hide"].waitAndTap()
        return MainScreen(app)
    }

    func tapActionButton(_ action: TokenAction) -> OnrampScreen {
        XCTContext.runActivity(named: "Tap token with label: \(action.rawValue)") { _ in
            actionButtons.buttons[action.rawValue].waitAndTap()
            switch action {
            case .buy:
                return OnrampScreen(app)
            }
        }
    }
}

enum TokenScreenElement: String, UIElement {
    case moreButton
    case hideTokenButton
    case tokenActionButtons

    var accessibilityIdentifier: String {
        switch self {
        case .moreButton:
            return TokenAccessibilityIdentifiers.moreButton
        case .hideTokenButton:
            return TokenAccessibilityIdentifiers.hideTokenButton
        case .tokenActionButtons:
            return TokenAccessibilityIdentifiers.actionButtonsList
        }
    }
}
