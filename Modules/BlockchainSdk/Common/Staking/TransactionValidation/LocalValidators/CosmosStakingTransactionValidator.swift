//
//  CosmosStakingTransactionValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Validates Cosmos staking transactions by checking message type prefix.
public enum CosmosStakingTransactionValidator {
    static let stakingModulePrefix = "/cosmos.staking."

    public static func validate(_ unsignedData: String) throws {
        guard !unsignedData.isEmpty, unsignedData.count.isMultiple(of: 2) else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let data = Data(hex: unsignedData)

        guard !data.isEmpty else {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let protoMessage: CosmosProtoMessage
        do {
            protoMessage = try CosmosProtoMessage(serializedBytes: data)
        } catch {
            throw StakingTransactionValidationError.emptyOrMalformedData
        }

        let messageType = protoMessage.delegateContainer.delegate.messageType

        guard messageType.contains(Self.stakingModulePrefix) else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Cosmos",
                details: "Message type '\(messageType)' does not contain '\(Self.stakingModulePrefix)'"
            )
        }
    }
}
