//
//  StakeKitTransactionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation

/// High-level protocol for preparing staking transactions data to send into blockchain
/// default implementation use low-level StakingTransactionDataProvider protocol
public protocol StakeKitTransactionsBuilder {
    associatedtype RawTransaction

    /// Prepare signed transactions ready to be submitted to blockchain
    /// - Parameters:
    ///   - transactions: original transactions from StakeKit
    ///   - publicKey: public key to sign
    ///   - signer: transaction signer
    /// - Returns: array of signed transactions
    func buildRawTransactions<T: TransactionDataConvertible>(
        from transactions: [T],
        publicKey: Wallet.PublicKey,
        signer: TransactionSigner
    ) async throws -> [RawTransaction]
    
//    func buildRawTransactions(
//        from transactions: [P2PTransaction],
//        publicKey: Wallet.PublicKey,
//        signer: TransactionSigner
//    ) async throws -> [RawTransaction]
}

extension StakeKitTransactionsBuilder where Self: StakeKitTransactionDataProvider {
    func buildRawTransactions<T: TransactionDataConvertible>(
        from transactions: [T],
        publicKey: Wallet.PublicKey,
        signer: TransactionSigner
    ) async throws -> [RawTransaction] {
        let preparedHashes = try transactions.map {
            try self.prepareDataForSign(transaction: $0)
        }

        let signatures: [SignatureInfo] = try await signer.sign(
            hashes: preparedHashes,
            walletPublicKey: publicKey
        ).async()

        return try zip(transactions, signatures).map { transaction, signature in
            try prepareDataForSend(transaction: transaction, signature: signature)
        }
    }
}

extension StakeKitTransactionsBuilder where Self: P2PTransactionDataProvider {
    func buildRawTransactions(
        from transactions: [P2PTransaction],
        publicKey: Wallet.PublicKey,
        signer: TransactionSigner
    ) async throws -> [RawTransaction] {
        let preparedHashes = try transactions.map {
            try self.prepareDataForSign(transaction: $0)
        }

        let signatures: [SignatureInfo] = try await signer.sign(
            hashes: preparedHashes,
            walletPublicKey: publicKey
        ).async()

        return try zip(transactions, signatures).map { transaction, signature in
            try prepareDataForSend(transaction: transaction, signature: signature)
        }
    }
}
