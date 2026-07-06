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
    typealias ContractType = Protocol_Transaction.Contract.ContractType
    static let stakingContractTypes: Set<ContractType> = [
        .voteWitnessContract, // 4 - Vote for validator (part of staking flow)
        .withdrawBalanceContract, // 13 - Claim staking rewards
        .freezeBalanceV2Contract, // 54 - Freeze TRX for energy/bandwidth
        .unfreezeBalanceV2Contract, // 55 - Unfreeze TRX
        .withdrawExpireUnfreezeContract, // 56 - Withdraw expired unfrozen TRX
        .delegateResourceContract, // 57 - Delegate energy/bandwidth
        .unDelegateResourceContract, // 58 - Undelegate energy/bandwidth
        .cancelAllUnfreezeV2Contract, // 59 - Cancel all pending unfreezes
    ]

    public static func validate(_ unsignedData: String) throws {
        let rawData = try makeRawData(from: unsignedData)
        try rawData.validateStakingContracts()
    }
}

private extension TronStakingTransactionValidator {
    static func makeRawData(from unsignedData: String) throws -> Protocol_Transaction.raw {
        guard !unsignedData.isEmpty, unsignedData.count.isMultiple(of: 2) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(hex: unsignedData)

        guard !data.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        do {
            return try Protocol_Transaction.raw(serializedBytes: data)
        } catch {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }
    }
}

private extension Protocol_Transaction.raw {
    func validateStakingContracts() throws {
        guard !contract.isEmpty else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Tron",
                details: "Transaction contains no contracts"
            )
        }

        for item in contract {
            guard TronStakingTransactionValidator.stakingContractTypes.contains(item.type) else {
                throw StakingTransactionValidationError.notAStakingTransaction(
                    network: "Tron",
                    details: "Contract type '\(item.type)' (rawValue: \(item.type.rawValue)) is not a staking operation"
                )
            }
        }
    }
}
