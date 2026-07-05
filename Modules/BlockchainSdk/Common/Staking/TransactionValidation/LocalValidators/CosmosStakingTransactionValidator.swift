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
    /// Claim rewards lives in the distribution module, not staking. Accept only this exact message —
    /// not the whole `/cosmos.distribution.` prefix, since e.g. MsgSetWithdrawAddress could redirect rewards.
    static let withdrawRewardMessageType = "/cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward"

    public static func validate(_ unsignedData: String) throws {
        // Hex string must have even length (2 chars per byte)
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

        guard messageType.hasPrefix(Self.stakingModulePrefix) || messageType == Self.withdrawRewardMessageType else {
            throw StakingTransactionValidationError.notAStakingTransaction(
                network: "Cosmos",
                details: "Message type '\(messageType)' is not a Cosmos staking or claim-reward operation"
            )
        }
    }
}
