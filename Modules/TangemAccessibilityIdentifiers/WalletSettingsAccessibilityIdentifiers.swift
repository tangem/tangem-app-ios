//
//  WalletSettingsAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum WalletSettingsAccessibilityIdentifiers {
    /// Wallet settings button with unique wallet name
    public static func walletSettingsButton(name: String) -> String {
        return "walletSettingsButton_\(name.lowercased().replacingOccurrences(of: " ", with: "_"))"
    }
}
