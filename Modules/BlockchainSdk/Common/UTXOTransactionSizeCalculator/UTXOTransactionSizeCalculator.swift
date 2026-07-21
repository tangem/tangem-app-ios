//
//  UTXOTransactionSizeCalculator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UTXOTransactionSizeCalculator {
    func dust(type: UTXOScriptType) -> Int
    func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) throws -> Int
}

enum UTXOTransactionSizeCalculatorError: LocalizedError {
    case unableToSpend

    var errorDescription: String? {
        switch self {
        case .unableToSpend: "Unable to spend"
        }
    }
}
