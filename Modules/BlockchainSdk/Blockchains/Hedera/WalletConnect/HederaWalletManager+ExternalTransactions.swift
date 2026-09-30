//
//  HederaWalletManager+ExternalTransactions.swift
//  BlockchainSdk
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension HederaWalletManager: HederaExternalTransactionProcessor {
    var consensusNodeAccountIds: [String] {
        transactionBuilder.consensusNodeAccountIds
    }

    func parseTransactionList(_ transactionList: Data) throws -> HederaExternalTransactionSummary {
        try transactionBuilder.buildCompiledTransaction(fromBytes: transactionList).makeSummary()
    }

    func signAndExecute(transactionList: Data, signer: TransactionSigner) async throws -> HederaExternalTransactionResult {
        let compiledTransaction = try transactionBuilder.buildCompiledTransaction(fromBytes: transactionList)
        let hashesToSign = try compiledTransaction.hashesToSign()

        let signatures = try await signer
            .sign(hashes: hashesToSign, walletPublicKey: wallet.publicKey)
            .eraseToAnyPublisher()
            .async()

        let signedTransaction = try transactionBuilder.buildForSend(
            transaction: compiledTransaction,
            signatures: signatures.map(\.signature)
        )

        return try await signedTransaction.execute()
    }

    func sign(transactionBody: Data, signer: TransactionSigner) async throws -> Data {
        // Decoding through the SDK rejects anything that is not a well-formed body before the card is touched.
        _ = try transactionBuilder.buildCompiledTransaction(fromBytes: HederaProtobufCodec.transaction(wrappingBody: transactionBody))

        return try await signatureMap(for: transactionBody, signer: signer)
    }

    func signMessage(_ message: String, signer: TransactionSigner) async throws -> Data {
        try await signatureMap(for: HederaProtobufCodec.signedMessageBytes(message), signer: signer)
    }

    private func signatureMap(for bytes: Data, signer: TransactionSigner) async throws -> Data {
        let hash = try transactionBuilder.hashToSign(for: bytes)

        let signature = try await signer
            .sign(hash: hash, walletPublicKey: wallet.publicKey)
            .eraseToAnyPublisher()
            .async()

        return try transactionBuilder.makeSignatureMap(signature: signature.signature)
    }
}
