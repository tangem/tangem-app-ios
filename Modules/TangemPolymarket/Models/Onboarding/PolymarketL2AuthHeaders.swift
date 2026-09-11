//
//  PolymarketL2AuthHeaders.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketL2AuthHeaders: Hashable, Sendable {
    public let values: [String: String]

    public init(ownerAddress: String, signature: String, timestamp: String, apiKey: String, passphrase: String) {
        values = [
            Constants.address: ownerAddress,
            Constants.signature: signature,
            Constants.timestamp: timestamp,
            Constants.apiKey: apiKey,
            Constants.passphrase: passphrase,
        ]
    }
}

// MARK: - Constants

private extension PolymarketL2AuthHeaders {
    enum Constants {
        static let address = "POLY_ADDRESS"
        static let signature = "POLY_SIGNATURE"
        static let timestamp = "POLY_TIMESTAMP"
        static let apiKey = "POLY_API_KEY"
        static let passphrase = "POLY_PASSPHRASE"
    }
}
