//
//  UTXOTransactionSerializer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UTXOTransactionSerializer {
    associatedtype Transaction

    func preImageHashes(transaction: Transaction) throws -> [UTXOTransactionSerializerPreImageHash]
    func compile(transaction: Transaction, signatures: [SignatureInfo]) throws -> Data
}

struct UTXOTransactionSerializerPreImageHash {
    let spendableType: UTXOLockingScript.SpendableType
    let hashToSign: Data
}

enum UTXOTransactionSerializerError: LocalizedError {
    case unsupported
    case spendableScriptNotFound
    case noDestinationAmount
    case walletCoreError(String)

    var errorDescription: String? {
        switch self {
        case .unsupported:
            return "Unsupported transaction type"
        case .spendableScriptNotFound:
            return "Spendable script not found"
        case .noDestinationAmount:
            return "No destination amount"
        case .walletCoreError(let message):
            return message
        }
    }
}

/// https://learnmeabitcoin.com/technical/transaction/input/sequence/
enum SequenceType {
    case zero
    case rbf
    case final

    var value: UInt32 {
        switch self {
        case .zero: .zero
        case .rbf: 0xfffffffd
        case .final: .max
        }
    }
}
