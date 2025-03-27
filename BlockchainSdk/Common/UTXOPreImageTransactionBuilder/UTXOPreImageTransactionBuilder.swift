//
//  UTXOPreImageTransactionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol UTXOPreImageTransactionBuilder {
    func preImage(
        outputs: [ScriptUnspentOutput],
        changeScript: UTXOScriptType,
        destination: UTXOPreImageDestination,
        fee: UTXOPreImageTransactionBuilderFee
    ) throws -> UTXOPreImageTransaction
}

struct UTXOPreImageDestination {
    let amount: UInt64
    let script: UTXOScriptType
}

enum UTXOPreImageTransactionBuilderFee {
    case exactly(fee: UInt64)
    case calculate(feeRate: UInt64)
}

struct UTXOPreImageTransaction {
    let outputs: [ScriptUnspentOutput]
    let destination: UInt64
    let change: UInt64
    let fee: UInt64
    let size: Int
}

enum UTXOPreImageTransactionBuilderError: LocalizedError {
    case noOutputs
    case wrongAmount
    case dustAmount
    case insufficientFunds
    case unableToFindSuitableUTXOs
}
