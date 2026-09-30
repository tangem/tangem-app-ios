//
//  HederaTransactionBuilder+External.swift
//  BlockchainSdk
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Hiero
import CryptoSwift
import TangemSdk

/// Support for transactions built by someone else (a WalletConnect dApp) rather than by this builder.
extension HederaTransactionBuilder {
    /// Decodes a `TransactionList` (or a single `Transaction`). `Hiero.Transaction.fromBytes` already enforces that
    /// every chunk carries the same body except for the node account id, which is the HIP-820 rule.
    func buildCompiledTransaction(fromBytes bytes: Data) throws -> CompiledTransaction {
        let transaction: Hiero.Transaction
        do {
            transaction = try Hiero.Transaction.fromBytes(bytes)
        } catch {
            throw HederaExternalTransactionError.invalidTransactionList(String(describing: error))
        }

        return CompiledTransaction(curve: curve, timeout: timeout, client: client, innerTransaction: transaction)
    }

    /// Node account ids of the consensus network the client currently knows.
    var consensusNodeAccountIds: [String] {
        client.network.values.map { $0.toString() }.sorted()
    }

    /// Signs arbitrary HAPI bytes the way transaction bodies are signed: EdDSA over the bytes, ECDSA over keccak256.
    func hashToSign(for bodyBytes: Data) throws -> Data {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return bodyBytes
        case .secp256k1:
            return bodyBytes.sha3(.keccak256)
        default:
            throw HederaExternalTransactionError.unsupportedCurve
        }
    }

    /// `SignatureMap` for one signature made with this account's key.
    func makeSignatureMap(signature: Data) throws -> Data {
        switch curve {
        case .ed25519, .ed25519_slip0010:
            return HederaProtobufCodec.signatureMap(publicKey: publicKey, signature: signature, kind: .ed25519)
        case .secp256k1:
            let compressed = try Secp256k1Key(with: publicKey).compress()
            return HederaProtobufCodec.signatureMap(publicKey: compressed, signature: signature, kind: .ecdsaSecp256k1)
        default:
            throw HederaExternalTransactionError.unsupportedCurve
        }
    }
}

extension HederaTransactionBuilder.CompiledTransaction {
    /// What the user must see before signing, read back from the decoded transaction.
    func makeSummary() -> HederaExternalTransactionSummary {
        let transaction = innerTransaction
        var hbarTransfers: [HederaExternalTransactionSummary.HbarTransfer] = []
        var tokenTransfers: [HederaExternalTransactionSummary.TokenTransfer] = []

        if let transfer = transaction as? TransferTransaction {
            hbarTransfers = transfer.hbarTransfers
                .map { HederaExternalTransactionSummary.HbarTransfer(accountId: $0.key.toString(), tinybars: $0.value.toTinybars()) }
                .sorted { $0.accountId < $1.accountId }
            tokenTransfers = transfer.tokenTransfers
                .flatMap { tokenId, accounts in
                    accounts.map { HederaExternalTransactionSummary.TokenTransfer(tokenId: tokenId.toString(), accountId: $0.key.toString(), amount: $0.value) }
                }
                .sorted { ($0.tokenId, $0.accountId) < ($1.tokenId, $1.accountId) }
        }

        return HederaExternalTransactionSummary(
            transactionType: String(describing: type(of: transaction)),
            payerAccountId: transaction.transactionId?.accountId.toString(),
            transactionId: transaction.transactionId?.toString(),
            nodeAccountIds: (transaction.nodeAccountIds ?? []).map { $0.toString() },
            memo: transaction.transactionMemo,
            maxFeeTinybars: transaction.maxTransactionFee?.toTinybars(),
            hbarTransfers: hbarTransfers,
            tokenTransfers: tokenTransfers
        )
    }

    /// Submits the (already signed) transaction and returns the HIP-820 result fields.
    func execute() async throws -> HederaExternalTransactionResult {
        let response = try await innerTransaction.execute(client, timeout)
        return HederaExternalTransactionResult(
            nodeId: response.nodeAccountId.toString(),
            transactionHash: response.transactionHash.data.hexString.lowercased(),
            transactionId: response.transactionId.toString()
        )
    }
}
