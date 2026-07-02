//
//  TronStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validates Tron staking transactions by checking contract type.
public enum TronStakingTransactionValidator {
    static let stakingContractTypes: Set<Protocol_Transaction.Contract.ContractType> = [
        .freezeBalanceV2Contract, // 54 - Freeze TRX for energy/bandwidth
        .unfreezeBalanceV2Contract, // 55 - Unfreeze TRX
        .withdrawExpireUnfreezeContract, // 56 - Withdraw expired unfrozen TRX
        .delegateResourceContract, // 57 - Delegate energy/bandwidth
        .cancelAllUnfreezeV2Contract, // 59 - Cancel all pending unfreezes
    ]

    public static func validate(_ unsignedData: String) throws {
        // Hex string must have even length (2 chars per byte)
        guard !unsignedData.isEmpty, unsignedData.count.isMultiple(of: 2) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(hex: unsignedData)

        guard !data.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let rawData: Protocol_Transaction.raw
        do {
            rawData = try Protocol_Transaction.raw(serializedBytes: data)
        } catch {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        guard let contract = rawData.contract.first else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Tron",
                details: "Transaction contains no contract"
            )
        }

        guard Self.stakingContractTypes.contains(contract.type) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Tron",
                details: "Contract type '\(contract.type)' is not a staking operation"
            )
        }
    }
}
