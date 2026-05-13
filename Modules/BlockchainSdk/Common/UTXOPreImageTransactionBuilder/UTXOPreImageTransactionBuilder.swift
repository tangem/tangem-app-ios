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
    ) async throws -> UTXOPreImageTransaction
}

struct UTXOPreImageDestination {
    let amount: Int
    let script: UTXOScriptType
}

enum UTXOPreImageTransactionBuilderFee {
    case exactly(fee: Int)
    case calculate(feeRate: Int)

    var isCalculation: Bool {
        switch self {
        case .calculate: true
        case .exactly: false
        }
    }
}

struct UTXOPreImageTransaction {
    let outputs: [ScriptUnspentOutput]
    let destination: Int
    let change: Int
    let fee: Int
    let size: Int
}

enum UTXOPreImageTransactionBuilderError: LocalizedError {
    case noOutputs
    case wrongAmount
    case dustAmount
    case insufficientFunds
    case unableToFindSuitableUTXOs
}
