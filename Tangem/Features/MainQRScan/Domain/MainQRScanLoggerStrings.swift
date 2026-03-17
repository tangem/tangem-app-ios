//
//  MainQRScanLoggerStrings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MainQRScanLoggerStrings {
    // MARK: - Flow coordinator

    static let qrScannerClosedByUser = "QR scanner closed by user"
    static let flowCoordinatorReceivedScanResult = "Flow coordinator received scan result"

    static func flowCoordinatorResolvedAction(_ actionName: String) -> String {
        "Flow coordinator resolved action=\(actionName)"
    }

    // MARK: - View model

    static let scannerSessionFailed = "Scanner session failed. Showing recovery options."
    static let failedToToggleFlash = "Failed to toggle the flash"

    // MARK: - Flow handler

    static let noWalletTokenItemsCollected = "No wallet token items collected. Wallet may be locked or have no tokens."

    // MARK: - Route resolver

    static let paymentQRParsedWithoutAvailableBlockchains = "Payment QR parsed, but no available blockchains loaded in repository."

    static let addressQRGloballyValidWithoutAvailableBlockchains = "Address QR is globally valid, but no available blockchains loaded in repository."
}
