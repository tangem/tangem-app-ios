//
//  StakeKitTransactionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation

protocol StakeKitTransactionBuilder {
    associatedtype RawTransaction

    func buildRawTransactions(
        from transactions: [StakeKitTransaction],
        wallet: Wallet,
        signer: TransactionSigner
    ) async throws -> [RawTransaction]
}

extension StakeKitTransactionBuilder where Self: StakeKitTransactionDataPrepare {
    func buildRawTransactions(
        from transactions: [StakeKitTransaction],
        wallet: Wallet,
        signer: TransactionSigner
    ) async throws -> [RawTransaction] {
        let preparedHashes = try transactions.map { try self.prepareDataForSign(transaction: $0) }

        let signatures: [SignatureInfo] = try await signer.sign(
            hashes: preparedHashes,
            walletPublicKey: wallet.publicKey
        ).async()

        return try zip(transactions, signatures).map { transaction, signature in
            try prepareDataForSend(transaction: transaction, signature: signature)
        }
    }
}
