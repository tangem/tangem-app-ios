//
//  UTXOPreImageTransactionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension UTXOPreImageTransactionBuilder where Self == BranchAndBoundPreImageTransactionBuilder {
    static var bitcoin: Self { .init(changeScript: .p2wpkh, dustThreshold: 10_000, calculator: .common) }
}

protocol UTXOPreImageTransactionBuilder {
    func preImage(
        outputs: [ScriptUnspentOutput],
        amount: UInt64,
        fee: UTXOPreImageTransactionBuilderFee,
        destinationScript: UTXOScriptType
    ) throws -> UTXOPreImageTransactionBuilderTransaction
}

enum UTXOPreImageTransactionBuilderFee {
    case exactly(fee: UInt64)
    case calculate(feeRate: UInt64)
}

struct UTXOPreImageTransactionBuilderTransaction {
    let outputs: [ScriptUnspentOutput]
    let transactionSize: Int
    let change: UInt64
    let fee: UInt64
}

enum UTXOPreImageTransactionBuilderError: LocalizedError {
    case noOutputs
    case wrongAmount
    case insufficientFunds
    case insufficientFundsForFee
    case unableToFindSuitableUTXOs
}
