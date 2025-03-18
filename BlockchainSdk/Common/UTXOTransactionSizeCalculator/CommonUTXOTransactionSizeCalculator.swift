//
//  CommonUTXOTransactionSizeCalculator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonUTXOTransactionSizeCalculator: UTXOTransactionSizeCalculator {
    func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) -> Int {
        let inputs = inputs.sum(by: \.script.type.inputSize)
        let outputs = outputs.sum(by: \.outputSize)
        return Constants.transactionHeaderSize + inputs + outputs
    }
}

extension CommonUTXOTransactionSizeCalculator {
    enum Constants {
        /// Basic transaction header components:
        /// - Version: 4 bytes
        /// - Input count (var_int): 1-9 bytes (typically 1 byte)
        /// - Output count (var_int): 1-9 bytes (typically 1 byte)
        /// - Locktime: 4 bytes
        static let transactionHeaderSize = 10
    }
}
