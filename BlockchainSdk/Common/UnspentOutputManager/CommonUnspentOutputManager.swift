//
//  CommonUnspentOutputManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

class CommonUnspentOutputManager {
    private let decimalValue: Decimal
    private var outputs: ThreadSafeContainer<[Data: [UnspentOutput]]> = [:]

    init(decimalValue: Decimal) {
        self.decimalValue = decimalValue
    }
}

extension CommonUnspentOutputManager: UnspentOutputManager {
    func update(outputs: [UnspentOutput], for script: Data) {
        self.outputs.mutate { $0[script] = outputs }
    }

    func allOutputs() -> [ScriptUnspentOutput] {
        outputs.read().flatMap { key, value in
            value.map { ScriptUnspentOutput(output: $0, script: key) }
        }
    }

    func selectOutputs(amount: UInt64, fee: UTXOSelector.Fee) throws -> [ScriptUnspentOutput] {
        let dust = (0.0001 * decimalValue).uint64Value
        let selector = UTXOSelector(dustThreshold: dust)
        let selected: [ScriptUnspentOutput] = try selector.select(outputs: allOutputs(), amount: amount, fee: fee).outputs

        return selected
    }

    func confirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { $0.isConfirmed }.reduce(0) { $0 + $1.amount }
    }

    func unconfirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { !$0.isConfirmed }.reduce(0) { $0 + $1.amount }
    }
}

/*
 let dust = (0.0001 * decimalValue).uint64Value
 let amount = (amount * decimalValue).uint64Value
 let selector = UTXOSelector(dustThreshold: dust, feeRate: feeRate)
 let selected: UTXOSelector.SuggestedResult<ScriptUnspentOutput> = try selector.select(outputs: allOutputs(), amount: amount)

 return selected
 */

extension CommonUnspentOutputManager {
    enum Errors: LocalizedError {
        case noOutputs

        var errorDescription: String? {
            switch self {
            case .noOutputs:
                return "No outputs"
            }
        }
    }
}
