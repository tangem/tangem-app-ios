//
//  CosmosStakeKitTransactionHelper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import WalletCore

struct CosmosStakeKitTransactionHelper {
    private let builder: CosmosTransactionBuilder

    init(builder: CosmosTransactionBuilder) {
        self.builder = builder
    }

    func prepareForSign(stakingTransaction: StakingTransaction) throws -> Data {
        let txInputData = try makeInput(stakingTransaction: stakingTransaction)
        return try builder.buildForSignRaw(txInputData: txInputData)
    }

    func buildForSend(
        stakingTransaction: StakingTransaction,
        signature: Data
    ) throws -> Data {
        let txInputData = try makeInput(stakingTransaction: stakingTransaction)
        return try builder.buildForSendRaw(txInputData: txInputData, signature: signature)
    }

    private func makeInput(
        stakingTransaction: StakingTransaction
    ) throws -> Data {
        guard let unsignedData = stakingTransaction.unsignedData as? String else {
            throw BlockchainSdkError.failedToBuildTx
        }
        let stakingProtoMessage = try CosmosProtoMessage(serializedData: Data(hex: unsignedData))

        let feeMessage = stakingProtoMessage.feeAndKeyContainer.feeContainer
        let feeValue = feeMessage.feeAmount

        guard let message = try CosmosMessage.createStakeMessage(message: stakingProtoMessage.delegateContainer.delegate) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        let serializedInput = try builder.serializeInput(
            gas: feeMessage.gas,
            feeAmount: feeValue.amount,
            feeDenomiation: feeValue.denomination,
            messages: [message],
            memo: nil
        )

        return serializedInput
    }
}
