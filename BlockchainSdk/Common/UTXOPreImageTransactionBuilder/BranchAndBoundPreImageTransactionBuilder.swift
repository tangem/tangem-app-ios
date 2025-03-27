//
//  BranchAndBoundPreImageTransactionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/**
 Branch and Bound algorithm
 https://github.com/bitcoin/bitcoin/blob/dbc89b604c4dae9702f1ff08abd4ed144a5fcb76/src/wallet/coinselection.cpp#L52
 https://bitcoin.stackexchange.com/questions/119919/how-does-the-branch-and-bound-coin-selection-algorithm-work
 */
struct BranchAndBoundPreImageTransactionBuilder {
    private typealias Input = ScriptUnspentOutput
    private typealias Output = UTXOScriptType
    private typealias Error = UTXOPreImageTransactionBuilderError
    private typealias FeeValueCalculation = (_ inputs: [Input], _ outputs: [Output]) -> (size: Int, fee: UInt64)

    private let dustThreshold: UInt64
    private let calculator: UTXOTransactionSizeCalculator

    init(
        dustThreshold: UInt64 = 10_000,
        calculator: UTXOTransactionSizeCalculator = .common
    ) {
        self.dustThreshold = dustThreshold
        self.calculator = calculator
    }
}

// MARK: - UTXOPreImageTransactionBuilder

extension BranchAndBoundPreImageTransactionBuilder: UTXOPreImageTransactionBuilder {
    func preImage(outputs: [ScriptUnspentOutput], changeScript: UTXOScriptType, destination: UTXOPreImageDestination, fee: UTXOPreImageTransactionBuilderFee) throws -> UTXOPreImageTransaction {
        guard destination.amount > 0 else {
            throw Error.wrongAmount
        }

        guard !outputs.isEmpty else {
            throw Error.noOutputs
        }

        let total = outputs.sum(by: \.amount)
        if total < destination.amount {
            throw Error.insufficientFunds
        }

        let sorted = outputs.sorted { $0.amount > $1.amount }
        let context = Context(changeScript: changeScript, destination: destination) { inputs, outputs in
            let size = calculator.transactionSize(inputs: inputs, outputs: outputs)
            switch fee {
            case .exactly(let fee):
                return (size: size, fee: fee)
            case .calculate(let feeRate):
                return (size: size, fee: UInt64(size) * feeRate)
            }
        }

        return try select(in: context, sorted: sorted)
    }
}

// MARK: - Private

extension BranchAndBoundPreImageTransactionBuilder {
    private func select(in context: Context, sorted: [Input]) throws -> UTXOPreImageTransaction {
        var bestVariant: UTXOPreImageTransaction?
        var tries = 0

        func search(selected: [Input], index: Int, currentValue: UInt64, remainingValue: UInt64) {
            tries += 1
            if tries > Constants.maxTries { return }

            // Estimate size with 2 outputs (Destination and change)
            let (size, fee) = context.feeValueCalculation(selected, [context.changeScript, context.destination.script])
            let requiredValue = context.destination.amount + fee

            // If we selected enough outputs to cover target amount + fee
            if currentValue >= requiredValue {
                let change = currentValue - requiredValue
                assert(change >= 0)

                var currentVariant = UTXOPreImageTransaction(
                    outputs: selected,
                    destination: context.destination.amount,
                    change: change,
                    fee: fee,
                    size: size
                )

                // If change less then dust just include it into destination value
                // and get rid of the change output
                if change < dustThreshold {
                    // Only destination without change
                    let (size, fee) = context.feeValueCalculation(selected, [context.destination.script])
                    let change = currentValue - context.destination.amount - fee
                    currentVariant = UTXOPreImageTransaction(
                        outputs: selected,
                        destination: context.destination.amount + change,
                        change: 0,
                        fee: fee,
                        size: size
                    )
                }

                // If currentVariant is better just use it as the best
                if bestVariant == nil || bestVariant?.better(than: currentVariant) == false {
                    bestVariant = currentVariant
                }

                return
            }

            // Stop if we reach last element or
            // Can't reach the target with remaining UTXOs
            if index >= sorted.count || currentValue + remainingValue < requiredValue {
                return
            }

            let remainingValue = remainingValue - sorted[index].amount
            // Branch 1: Include current UTXO
            search(selected: selected + [sorted[index]], index: index + 1, currentValue: currentValue + sorted[index].amount, remainingValue: remainingValue)

            // Branch 2: Exclude current UTXO
            search(selected: selected, index: index + 1, currentValue: currentValue, remainingValue: remainingValue)
        }

        search(selected: [], index: 0, currentValue: 0, remainingValue: sorted.sum(by: \.amount))

        guard let bestVariant, !bestVariant.outputs.isEmpty else {
            throw Error.unableToFindSuitableUTXOs
        }

        return bestVariant
    }
}

private extension UTXOPreImageTransaction {
    func better(than transaction: UTXOPreImageTransaction) -> Bool {
        let feeIsBetter = fee < transaction.fee

        return feeIsBetter
    }
}

extension BranchAndBoundPreImageTransactionBuilder {
    private struct Context {
        let changeScript: UTXOScriptType
        let destination: UTXOPreImageDestination
        let feeValueCalculation: FeeValueCalculation
    }

    private enum Constants {
        static let maxTries: Int = 100_000
    }
}
