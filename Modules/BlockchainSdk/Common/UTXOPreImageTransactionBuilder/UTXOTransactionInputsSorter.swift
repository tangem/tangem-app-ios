//
//  UTXOTransactionInputsSorter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol UTXOTransactionInputsSorter {
    func sort(inputs: [ScriptUnspentOutput]) -> [ScriptUnspentOutput]
}

struct BIP69UTXOTransactionInputsSorter: UTXOTransactionInputsSorter {
    func sort(inputs: [ScriptUnspentOutput]) -> [ScriptUnspentOutput] {
        inputs.sorted { lhs, rhs in
            if lhs.output.txId != rhs.output.txId {
                return lhs.output.txId.lexicographicallyPrecedes(rhs.output.txId)
            } else {
                return lhs.output.index < rhs.output.index
            }
        }
    }
}
