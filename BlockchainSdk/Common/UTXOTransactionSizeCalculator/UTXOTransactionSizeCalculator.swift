//
//  UTXOTransactionSizeCalculator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UTXOTransactionSizeCalculator {
    func transactionSize(inputs: [ScriptUnspentOutput], outputs: [UTXOScriptType]) -> Int
}

extension UTXOTransactionSizeCalculator where Self == CommonUTXOTransactionSizeCalculator {
    static var common: Self { .init() }
}
