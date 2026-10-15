//
//  WelcomeAccessibilityIdentifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum WelcomeAccessibilityIdentifiers {
    private static let prefix = "welcome"

    public static let createWalletButton = "\(prefix)CreateWalletButton"
    public static let existingWalletButton = "\(prefix)ExistingWalletButton"
    public static let buyTangemButton = "\(prefix)BuyTangemButton"

    /// Shared by both action sheets: only one of them is presented at a time.
    public static let actionSheetHardwareRow = "\(prefix)ActionSheetHardwareRow"
    public static let actionSheetMobileRow = "\(prefix)ActionSheetMobileRow"
    public static let actionSheetImportRow = "\(prefix)ActionSheetImportRow"
}
