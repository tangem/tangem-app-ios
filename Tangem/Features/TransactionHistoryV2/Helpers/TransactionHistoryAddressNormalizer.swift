//
//  TransactionHistoryAddressNormalizer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

/// Normalizes user/contract addresses using following rules:
/// EVM addresses are case-insensitive — the mixed case of EIP-55 only carries a checksum — and are lowercased.
/// Addresses of all other chains are case-sensitive and are left untouched.
enum TransactionHistoryAddressNormalizer {
    /// - Note: `Blockchain.allMainnetCases` is fine here because the caller is expected to provide supported networks only.
    private static let blockchainsKeyedByNetworkID = Blockchain
        .allMainnetCases
        .keyedFirst(by: \.networkId)

    static func normalize(_ address: String, isEvm: Bool) -> String {
        return isEvm ? address.lowercased() : address
    }

    static func normalize(_ address: String, networkID: String) -> String {
        guard let blockchain = blockchainsKeyedByNetworkID[networkID] else {
            TransactionHistoryLogger.warning("Unknown/unsupported network id \(networkID), leaving address as is")

            return address
        }

        return normalize(address, isEvm: blockchain.isEvm)
    }
}

// MARK: - Convenience extensions

extension TransactionHistoryAddressNormalizer {
    static func normalize(_ address: String?, networkID: String?) -> String? {
        guard let address, let networkID else {
            return address
        }

        return normalize(address, networkID: networkID)
    }
}
