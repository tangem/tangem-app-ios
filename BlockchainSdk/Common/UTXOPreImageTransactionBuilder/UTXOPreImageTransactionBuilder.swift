//
//  UTXOPreImageTransactionBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct UTXOPreImageTransactionBuilder {
    typealias Input = ScriptUnspentOutput
    typealias Output = UTXOScriptType

    private typealias FeeValueCalculation = (_ inputs: [Input], _ outputs: [Output]) -> (size: Int, fee: UInt64)

    private let outputs: [Input]
    private let amount: UInt64
    private let fee: Fee
    private let dustThreshold: UInt64
    private let changeScript: UTXOScriptType
    private let destinationScript: UTXOScriptType
    private let calculator: UTXOTransactionSizeCalculator

    init(
        outputs: [Input],
        amount: UInt64,
        fee: Fee,
        changeScript: UTXOScriptType,
        destinationScript: UTXOScriptType,
        dustThreshold: UInt64 = 10_000,
        calculator: UTXOTransactionSizeCalculator = .common
    ) {
        self.outputs = outputs
        self.amount = amount
        self.fee = fee
        self.changeScript = changeScript
        self.destinationScript = destinationScript
        self.dustThreshold = dustThreshold
        self.calculator = calculator
    }

    /**
     Branch and Bound algorithm
     https://github.com/bitcoin/bitcoin/blob/dbc89b604c4dae9702f1ff08abd4ed144a5fcb76/src/wallet/coinselection.cpp#L52
     https://bitcoin.stackexchange.com/questions/119919/how-does-the-branch-and-bound-coin-selection-algorithm-work
     */
    func preImage() throws -> PreImageTransaction {
        guard amount > 0 else {
            throw Error.wrongAmount
        }

        guard !outputs.isEmpty else {
            throw Error.noOutputs
        }

        let total = outputs.sum(by: \.amount)
        if total < amount {
            throw Error.insufficientFunds
        }

        let sorted = outputs.sorted { $0.amount > $1.amount }
        let feeValueCalculation: FeeValueCalculation = { inputs, outputs in
            let size = calculator.transactionSize(inputs: inputs, outputs: outputs)
            switch fee {
            case .exactly(let fee):
                return (size: size, fee: fee)
            case .calculate(let feeRate):
                return (size: size, fee: UInt64(size) * feeRate)
            }
        }

        return try select(sorted: sorted, targetValue: amount, feeValueCalculation: feeValueCalculation)
    }

    private func select(sorted: [Input], targetValue: UInt64, feeValueCalculation: FeeValueCalculation) throws -> PreImageTransaction {
        let maxAmount = sorted.sum(by: \.amount)

        var bestSelection: [Input] = []
        var bestTransactionSize: Int = feeValueCalculation(sorted, [changeScript, destinationScript]).size // Destination and change
        var bestFee: UInt64 = maxAmount
        var bestChange: UInt64 = maxAmount
        var tries = 0

        func search(selected: [Input], index: Int, currentValue: UInt64, remainingValue: UInt64) {
            tries += 1
            if tries > Constants.maxTries { return }

            // Estimate size with 2 outputs (Destination and change)
            let calculation = feeValueCalculation(selected, [changeScript, destinationScript])
            var currentSize = calculation.size
            var currentFee = calculation.fee
            let requiredValue = targetValue + currentFee

            // If we selected enough outputs to cover target amount + fee
            if currentValue >= requiredValue {
                var currentChange = currentValue - requiredValue

                assert(currentChange >= 0)

                // If change less then dust just include it into fee
                // and reduce the change output
                if currentChange < dustThreshold {
                    // Only destination without change
                    let calculation = feeValueCalculation(selected, [destinationScript])
                    currentSize = calculation.size
                    currentFee = calculation.fee
                    currentChange = 0
                }

                // Try to find a set with minimal fee / size
                let feeIsBetter = currentFee < bestFee

                if bestSelection.isEmpty || feeIsBetter {
                    bestSelection = selected
                    bestTransactionSize = currentSize
                    bestFee = currentFee
                    bestChange = currentChange
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

        search(selected: [], index: 0, currentValue: 0, remainingValue: maxAmount)

        if maxAmount < targetValue + bestFee {
            throw Error.insufficientFundsForFee
        }

        if bestSelection.isEmpty {
            throw Error.unableToFindSuitableUTXOs
        }

        return .init(outputs: bestSelection, transactionSize: bestTransactionSize, change: bestChange, fee: bestFee)
    }
}

extension UTXOPreImageTransactionBuilder {
    enum Constants {
        static let maxTries: Int = 100_000
    }

    enum Fee {
        case exactly(fee: UInt64)
        case calculate(feeRate: UInt64)
    }

    struct PreImageTransaction {
        let outputs: [Input]
        let transactionSize: Int
        let change: UInt64
        let fee: UInt64
    }

    enum Error: LocalizedError {
        case noOutputs
        case wrongAmount
        case insufficientFunds
        case insufficientFundsForFee
        case unableToFindSuitableUTXOs
    }
}
