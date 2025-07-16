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
            scanButton.waitAndTap()
            let walletButton = app.buttons[name.rawValue]
            walletButton.waitAndTap()

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
