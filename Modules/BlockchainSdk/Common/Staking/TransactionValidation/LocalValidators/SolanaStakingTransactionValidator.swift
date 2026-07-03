//
//  SolanaStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validates Solana staking transactions by checking for Stake program ID in transaction data.
public enum SolanaStakingTransactionValidator {
    /// Stake program ID in base58: Stake11111111111111111111111111111111111111
    static let stakeProgramBytes = Base58.decode("Stake11111111111111111111111111111111111111")

    public static func validate(_ unsignedData: String) throws {
        // Hex string must have even length (2 chars per byte)
        guard !unsignedData.isEmpty, unsignedData.count.isMultiple(of: 2) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(hex: unsignedData)

        guard !data.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        guard data.containsSubdata(stakeProgramBytes) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Solana",
                details: "Transaction does not contain Stake program ID"
            )
        }
    }
}

private extension Data {
    func containsSubdata(_ subdata: Data) -> Bool {
        guard !subdata.isEmpty, subdata.count <= count else {
            return false
        }

        return range(of: subdata) != nil
    }
}
