//
//  DetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation
import TangemAccessibilityIdentifiers

final class DetailsScreen: ScreenBase<DetailsScreenElement> {
    private lazy var walletSettingsButton = button(.walletSettingsButton)

    func openWalletSettings() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Open wallet settings screen") { _ in
            walletSettingsButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }
}

enum DetailsScreenElement: String, UIElement {
    case walletSettingsButton

    var accessibilityIdentifier: String {
        switch self {
        case .walletSettingsButton:
            return WalletSettingsAccessibilityIdentifiers.walletSettingsButton
        }
    }
}
