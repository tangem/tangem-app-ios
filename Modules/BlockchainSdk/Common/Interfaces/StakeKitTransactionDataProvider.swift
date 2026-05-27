//
//  StakeKitTransactionDataProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol StakeKitTransactionDataProvider: StakingTransactionDataProvider {
    func prepareDataForSign(transaction: StakeKitTransaction) throws -> Data
    func prepareDataForSend(transaction: StakeKitTransaction, signature: SignatureInfo) throws -> RawTransaction
}

extension StakeKitTransactionDataProvider {
    func prepareDataForSign<T: StakingTransaction>(transaction: T) throws -> Data {
        guard let stakeKitTransaction = transaction as? StakeKitTransaction else {
            throw BlockchainSdkError.failedToBuildTx
        }
        return try prepareDataForSign(transaction: stakeKitTransaction)
    }

    func prepareDataForSend<T: StakingTransaction>(transaction: T, signature: SignatureInfo) throws -> RawTransaction {
        guard let stakeKitTransaction = transaction as? StakeKitTransaction else {
            throw BlockchainSdkError.failedToBuildTx
        }
        return try prepareDataForSend(transaction: stakeKitTransaction, signature: signature)
    }
}
