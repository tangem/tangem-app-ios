//
//  UTXOSelector.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct UTXOSelector {
    let dustThreshold: UInt64

    enum Fee {
        case exactly(fee: UInt64)
        case calculate(feeRate: UInt64)
    }

    /// 0.0001 BTC as in `BitcoinWalletManager`
    init(dustThreshold: UInt64 = 10_000) {
        self.dustThreshold = dustThreshold
    }

    func select<Output: SelectableUnspentOutput>(outputs: [Output], amount: UInt64, fee: Fee) throws -> PreimageTransaction<Output> {
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
            let size = calculateTransactionSize(inputs: inputs, outputs: outputs)
            switch fee {
            case .exactly(let fee):
                return (size: size, fee: fee)
            case .calculate(let feeRate):
                return (size: size, fee: UInt64(size) * feeRate)
            }
        }

        return try select(sorted: sorted, targetValue: amount, feeValueCalculation: feeValueCalculation)
    }

    private typealias FeeValueCalculation = (_ inputs: Int, _ outputs: Int) -> (size: Int, fee: UInt64)

    private func select<Output: SelectableUnspentOutput>(sorted: [Output], targetValue: UInt64, feeValueCalculation: FeeValueCalculation) throws -> PreimageTransaction<Output> {
        let maxAmount = sorted.sum(by: \.amount)

        var bestSelection: [Output] = []
        var bestTransactionSize: Int = calculateTransactionSize(inputs: sorted.count, outputs: 2) // Destination and change
        var bestFee: UInt64 = maxAmount
        var bestChange: UInt64 = maxAmount
        var tries = 0

        func search(selected: [Output], index: Int, currentValue: UInt64, remainingValue: UInt64) {
            tries += 1
            if tries > Constants.maxTries { return }

            // Estimate size with 2 outputs (Destination and change)
            let calculation = feeValueCalculation(selected.count, 2)
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
                    let calculation = feeValueCalculation(selected.count, 1)
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

    private func calculateTransactionSize(inputs: Int, outputs: Int) -> Int {
        Constants.headerSize + (inputs * Constants.inputSize) + (outputs * Constants.outputSize)
    }
}

extension UTXOSelector {
    protocol SelectableUnspentOutput {
        var amount: UInt64 { get }
    }
}

extension UTXOSelector {
    enum Constants {
        /**
         Input Size (148 bytes):
         Transaction ID (32 bytes)
         Output Index (4 bytes)
         Script Length (1 byte)
         Unlocking Script (varies, but typically around 107 bytes for P2PKH)
         Sequence Number (4 bytes)
         */
        static let inputSize: Int = 148
        /**
         Output Size (34 bytes):
         Value (8 bytes)
         Script Length (1 byte)
         Locking Script (25 bytes for P2PKH)
         */
        static let outputSize: Int = 34
        /**
         Header Size (10 bytes):
         Version (4 bytes)
         Input Count (varies, but we use 1 byte)
         Output Count (varies, but we use 1 byte)
         Locktime (4 bytes)
         */
        static let headerSize: Int = 10

        static let maxTries: Int = 100_000
    }

    struct PreimageTransaction<Output: SelectableUnspentOutput> {
        let outputs: [Output]
        let transactionSize: Int
        let change: UInt64
        let fee: UInt64
    }

    enum UTXOSelectionAlgorithm {
        /// Branch and Bound
        /// https://github.com/bitcoin/bitcoin/blob/dbc89b604c4dae9702f1ff08abd4ed144a5fcb76/src/wallet/coinselection.cpp#L52
        /// https://bitcoin.stackexchange.com/questions/119919/how-does-the-branch-and-bound-coin-selection-algorithm-work
        case bnb

        /**
         * Method for collecting minimum required UTXOs for transaction (based on binary search)
         * The collection is processed as follows:
         *  1. Sorts the list of all available UTXOs that can be used in a transaction
         *  2. By iterating through this list, the algorithm selects the closest UTXO to the required transaction amount
         *     (amount + commission)
         *  3. After the previous iteration, the total required amount will be reduced by the previously selected UTXO
         *     and it ready to search for the next UTXO closest to this amount
         *  4. When all the UTXOs necessary to complete the requested transaction amount have been collected,
         *     the function returns a list of UTXOs sorted in descending order of the amount
         *  5. If necessary UTXOs result in change with output UTXO less than dust add smallest UTXO
         */
        case binary
    }

    enum Error: LocalizedError {
        case noOutputs
        case wrongAmount
        case insufficientFunds
        case insufficientFundsForFee
        case unableToFindSuitableUTXOs
    }
}

extension ScriptUnspentOutput: UTXOSelector.SelectableUnspentOutput {}
extension UnspentOutput: UTXOSelector.SelectableUnspentOutput {}
