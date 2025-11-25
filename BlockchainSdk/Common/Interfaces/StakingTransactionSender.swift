//
//  StakingTransactionSender.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

/// High-level protocol for preparing, signing and sending staking transactions
public protocol StakingTransactionSender {
    /// Return stream with tx which was sent one by one
    /// If catch error stream will be stopped
    /// In case when manager already implemented the `StakeKitTransactionSenderProvider` method will be not required
    func sendStakeKit(
        transactions: [StakeKitTransaction],
        signer: TransactionSigner,
        transactionStatusProvider: some StakeKitTransactionStatusProvider,
        delay second: UInt64?
    ) async throws -> AsyncThrowingStream<StakeKitTransactionSendResult, Error>

    func sendP2P(
        transaction: P2PTransaction,
        signer: TransactionSigner,
        executeSend: @escaping (String) async throws -> String
    ) async throws -> TransactionSendResult
}

extension StakingTransactionSender {
    func sendP2P(
        transaction: P2PTransaction,
        signer: TransactionSigner,
        executeSend: @escaping (String) async throws -> String
    ) async throws -> TransactionSendResult {
        BSDKLogger.error(error: "Attempt to send P2P transaction on unsupported chain")
        throw BlockchainSdkError.failedToSendTx
    }
}
