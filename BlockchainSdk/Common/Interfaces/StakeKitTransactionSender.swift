//
//  StakeKitTransactionSender.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

/// High-level protocol for preparing, signing and sending staking transactions
public protocol StakeKitTransactionSender {
    /// Return stream with tx which was sent one by one
    /// If catch error stream will be stopped
    /// In case when manager already implemented the `StakeKitTransactionSenderProvider` method will be not required
    func sendStakeKit(
        transactions: [StakeKitTransaction],
        signer: TransactionSigner,
        transactionStatusProvider: some StakeKitTransactionStatusProvider,
        delay second: UInt64?
    ) async throws -> AsyncThrowingStream<StakeKitTransactionSendResult, Error>
}
