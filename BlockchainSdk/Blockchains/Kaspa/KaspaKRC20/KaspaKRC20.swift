//
// KaspaKRC20.swift
// BlockchainSdk
//
// Created by [REDACTED_AUTHOR]
// Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoSwift

struct KaspaIncompleteTokenTransactionStorageID: Hashable, Identifiable {
    let id: String

    init(
        walletAddress: String,
        contractAddress: String
    ) {
        id = "KaspaTokenIncompleteTransactions_\(walletAddress.sha256())_\(contractAddress)"
    }
}

enum KaspaKRC20 {
    struct TransactionGroup {
        let kaspaCommitTransaction: KaspaTransaction
        let kaspaRevealTransaction: KaspaTransaction
        let hashesCommit: [Data]
        let hashesReveal: [Data]
    }

    struct TransactionMeta {
        let redeemScriptCommit: KaspaKRC20.RedeemScript
        let incompleteTransactionParams: KaspaKRC20.IncompleteTokenTransactionParams
    }

    struct CommitTransaction {
        let transaction: KaspaTransaction
        let hashes: [Data]
        let redeemScript: KaspaKRC20.RedeemScript
        let sourceAddress: String
        let params: IncompleteTokenTransactionParams
    }

    struct RevealTransaction {
        let transaction: KaspaTransaction
        let hashes: [Data]
        let redeemScript: KaspaKRC20.RedeemScript
    }

    struct IncompleteTokenTransactionParams: TransactionParams, Codable {
        let transactionId: String
        /// Original tx amount, as entered by user.
        let amount: Decimal
        /// Calculated tx amount, in atomic units of the asset.
        let targetOutputAmount: UInt64
        let envelope: KaspaKRC20.Envelope
    }

    struct RevealTransactionFeeParameter: FeeParameters {
        let amount: Amount
    }

    struct Envelope: Codable {
        let p: String
        let op: String
        let amt: String
        let to: String
        let tick: String

        init(amount: Decimal, recipient: String, ticker: String) {
            p = "krc-20"
            op = "transfer"
            amt = amount.description
            to = recipient
            tick = ticker
        }

        var data: Data {
            let kasplexId = "kasplex".data(using: .utf8)!
            let kasplexIdCount = UInt8(kasplexId.count & 0xff)

            let payload = "{\"amt\":\"\(amt)\",\"op\":\"\(op)\",\"p\":\"\(p)\",\"tick\":\"\(tick)\",\"to\":\"\(to)\"}".data(using: .utf8)!
            let payloadCount = UInt8(payload.count & 0xff)

            let elements = [
                OpCode.OP_FALSE.value.data,
                OpCode.OP_IF.value.data,
                kasplexIdCount.data,
                kasplexId,
                OpCode.OP_1.value.data,
                OpCode.OP_0.value.data,
                OpCode.OP_0.value.data,
                OpCode.OP_PUSHDATA1.value.data,
                payloadCount.data,
                payload,
                OpCode.OP_ENDIF.value.data,
            ]

            return elements.reduce(Data(), +)
        }
    }

    struct RedeemScript {
        let publicKey: Data
        let envelope: KaspaKRC20.Envelope

        init(publicKey: Data, envelope: KaspaKRC20.Envelope) {
            self.publicKey = publicKey
            self.envelope = envelope
        }

        var data: Data {
            return UInt8(publicKey.count & 0xff).data + publicKey + OpCode.OP_CODESEPARATOR.value.data + envelope.data
        }

        var redeemScriptHash: Data {
            return OpCode.OP_HASH256.value.data + UInt8(32).data + data.hashBlake2b(outputLength: 32)! + OpCode.OP_EQUAL.value.data
        }
    }

    struct IncompleteTokenTransactionComparator {
        func isIncompleteTokenTransaction(
            _ incompleteTokenTransaction: IncompleteTokenTransactionParams,
            equalTo transaction: Transaction
        ) -> Bool {
            return incompleteTokenTransaction.amount == transaction.amount.value
                && incompleteTokenTransaction.envelope.to == transaction.destinationAddress
        }
    }

    enum Error: Swift.Error {
        case unableToFindIncompleteTokenTransaction
        case invalidIncompleteTokenTransaction
        case unableToBuildRevealTransaction
    }

    enum Constants {
        static let revealTransactionMass: Decimal = 4100
        static let revealTransactionSendDelay: TimeInterval = 2.0
    }
}
