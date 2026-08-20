//
//  PolymarketCLOBAuthHeaders.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct PolymarketCLOBAuthHeaders: Hashable, Sendable {
    public let values: [String: String]

    public init(ownerAddress: String, signature: String, timestamp: String, nonce: String) {
        values = [
            Constants.address: ownerAddress,
            Constants.signature: signature,
            Constants.timestamp: timestamp,
            Constants.nonce: nonce,
        ]
    }
}

// MARK: - Constants

private extension PolymarketCLOBAuthHeaders {
    enum Constants {
        static let address = "POLY_ADDRESS"
        static let signature = "POLY_SIGNATURE"
        static let timestamp = "POLY_TIMESTAMP"
        static let nonce = "POLY_NONCE"
    }
}
