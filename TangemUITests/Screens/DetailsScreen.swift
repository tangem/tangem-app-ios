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
    /// Open wallet settings for specific wallet by name
    func openWalletSettings(for walletName: String) -> CardSettingsScreen {
        XCTContext.runActivity(named: "Open wallet settings for wallet: \(walletName)") { _ in
            let specificWalletButton = app.buttons[WalletSettingsAccessibilityIdentifiers.walletSettingsButton(name: walletName)]
            specificWalletButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }
}

enum DetailsScreenElement: UIElement {
    var accessibilityIdentifier: String {
        return ""
    }
}
