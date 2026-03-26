//
//  MainQRScanLoggerStrings.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MainQRScanLoggerStrings {
    static let walletConnectViewModelCreationFailed = "Failed to create WalletConnect view model for scanned QR"
    static let scannerSessionFailed = "Scanner session failed. Showing recovery options."
    static let addressQRGloballyValidWithoutAvailableBlockchains = "Address QR is globally valid, but no available blockchains loaded in repository."

    static func unknownQueryParameters(blockchain: String, parameters: [String: String]) -> String {
        let params = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return "QR URI for \(blockchain) contains unknown query parameters that may carry important data: [\(params)]"
    }

    static func tronAmountTreatedAsRaw(rawValue: String) -> String {
        "Tron QR amount '\(rawValue)' has no decimal point and exceeds threshold (\(MainQRParserConstants.tronRawAmountThreshold)), treating as raw integer (needs decimals shift)"
    }
}
