//
//  BNBStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validates BNB staking transactions by checking for StakeHub contract address.
public enum BNBStakingTransactionValidator {
    static let stakeHub = "0x0000000000000000000000000000000000002002"

    public static func validate(_ unsignedData: String) throws {
        guard !unsignedData.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(unsignedData.utf8)

        let transaction: EthereumCompiledTransactionData
        do {
            transaction = try JSONDecoder().decode(EthereumCompiledTransactionData.self, from: data)
        } catch {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let toAddress = transaction.to.lowercased()

        guard toAddress == Self.stakeHub.lowercased() else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "BNB",
                details: "Transaction 'to' address '\(transaction.to)' is not the StakeHub contract"
            )
        }
    }
}
