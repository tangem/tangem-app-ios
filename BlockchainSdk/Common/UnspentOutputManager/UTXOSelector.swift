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

    /// Минимальный порог "пыли" в сатоши
    init(dustThreshold: UInt64 = 546) {
        self.dustThreshold = dustThreshold
    }

    func select<Output: SelectableUnspentOutput>(outputs: [Output], amount: UInt64, fee: Fee) throws -> SuggestedResult<Output> {
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

        switch fee {
        case .exactly(let fee):
            let sorted = outputs.sorted { $0.amount > $1.amount }
            return try select(sorted: sorted, targetValue: amount, fee: fee)
        case .calculate(let feeRate):
            let sorted = outputs.sorted { effectiveValue(output: $0, feeRate: feeRate) > effectiveValue(output: $1, feeRate: feeRate) }
            return try select(sorted: sorted, targetValue: amount, feeRate: feeRate)
        }
    }

//    private func binarySelect<Output: SelectableUnspentOutput>(sorted: [Output], targetValue amount: UInt64) throws -> [Output] {
//        var left = 0
//        var right = sorted.count - 1
//        var best: [Output]?
//
//        while left <= right {
//            let mid = (left + right) / 2
//            let candidate = Array(sorted[mid...])
//            let candidateSum = candidate.sum(by: \.amount)
//
//            if candidateSum >= amount {
//                best = candidate
//                right = mid - 1
//            } else {
//                left = mid + 1
//            }
//        }
//
//        guard var bestMatch = best else {
//            throw Error.unableToFindSuitableUTXOs
//        }
//
//        let spend = bestMatch.sum(by: \.amount)
//        let change = spend - amount
//        if change > 0, change < dustThreshold {
//            // Check if resulting spending UTXOs leads to output UTXO having amount less than dust.
//            // In that case add smallest UTXO so output UTXO was greater than dust.
//            sorted.last.map { bestMatch.append($0) }
//        }
//
//        return bestMatch
//    }

    private func select<Output: SelectableUnspentOutput>(sorted: [Output], targetValue: UInt64, fee: UInt64) throws -> SuggestedResult<Output> {
        var bestSelection: [Output] = []
        var bestTransactionSize: Int = calculateTransactionSize(inputs: sorted.count, outputs: 2) // Destination and change
        var bestChange: UInt64 = sorted.sum(by: \.amount)
        var bestFee: UInt64 = .max
        var tries = 0

        func search(selected: [Output], index: Int, currentValue: UInt64, remainingValue: UInt64) {
            tries += 1
            if tries > Constants.maxTries { return }

            var transactionSize = calculateTransactionSize(inputs: selected.count, outputs: 2) // Destination and change
            var requiredValue = targetValue + fee
            var currentChange = currentValue - targetValue

            // If change less then dust just include it into fee
            // and reduce the change output
            if currentChange < dustThreshold {
                transactionSize = calculateTransactionSize(inputs: selected.count, outputs: 1) // Only destination
                requiredValue = targetValue + fee + currentChange
                currentChange = 0
            }

            // If we found enough outputs to cover target amount
            if currentValue >= requiredValue {
                let changeIsBetter = currentChange >= 0 || currentChange >= dustThreshold && currentChange < bestChange
                let sizeIsBetter = transactionSize < bestTransactionSize

                if bestSelection.isEmpty || changeIsBetter, sizeIsBetter {
                    bestSelection = selected
                    bestTransactionSize = transactionSize
                    bestChange = currentChange
                }

                return
            }

            // Stop if we reach last element or
            // Can't reach the target with remaining UTXOs
            if index >= sorted.count || currentValue + remainingValue < targetValue {
                return
            }

            let remainingValue = remainingValue - sorted[index].amount
            // Branch 1: Include current UTXO
            search(selected: selected + [sorted[index]], index: index + 1, currentValue: currentValue + sorted[index].amount, remainingValue: remainingValue)

            // Branch 2: Exclude current UTXO
            search(selected: selected, index: index + 1, currentValue: currentValue, remainingValue: remainingValue)
        }

        search(selected: [], index: 0, currentValue: 0, remainingValue: sorted.sum(by: \.amount))

        guard !bestSelection.isEmpty else {
            throw Error.unableToFindSuitableUTXOs
        }

        return .init(outputs: bestSelection, transactionSize: bestTransactionSize, change: bestChange, fee: bestFee)
    }

    private func select<Output: SelectableUnspentOutput>(sorted: [Output], targetValue: UInt64, feeRate: UInt64) throws -> SuggestedResult<Output> {
        var bestSelection: [Output] = []
        var bestTransactionSize: Int = calculateTransactionSize(inputs: sorted.count, outputs: 2) // Destination and change
        var bestChange: UInt64 = sorted.sum(by: \.amount)
        var bestFee: UInt64 = .max
        var tries = 0

        func search(selected: [Output], index: Int, currentValue: UInt64, remainingValue: UInt64) {
            tries += 1
            if tries > Constants.maxTries { return }

            var transactionSize = calculateTransactionSize(inputs: selected.count, outputs: 2) // Destination and change
            var estimatedFee = UInt64(transactionSize) * feeRate
            var requiredValue = targetValue + estimatedFee
            var currentChange = currentValue - targetValue

            // If change less then dust just include it into fee
            // and reduce the change output
            if currentChange < dustThreshold {
                transactionSize = calculateTransactionSize(inputs: selected.count, outputs: 1) // Only destination
                estimatedFee = UInt64(transactionSize) * feeRate + currentChange
                requiredValue = targetValue + estimatedFee
                currentChange = 0
            }

            // If we found enough outputs to cover target amount
            if currentValue >= requiredValue {
                let changeIsBetter = currentChange >= 0 || currentChange >= dustThreshold && currentChange < bestChange
                let feeIsBetter = estimatedFee < bestFee

                if bestSelection.isEmpty || changeIsBetter, feeIsBetter {
                    bestSelection = selected
                    bestTransactionSize = transactionSize
                    bestChange = currentChange
                    bestFee = estimatedFee
                }

                return
            }

            // Stop if we reach last element or
            // Can't reach the target with remaining UTXOs
            if index >= sorted.count || currentValue + remainingValue < targetValue {
                return
            }

            let remainingValue = remainingValue - sorted[index].amount
            // Branch 1: Include current UTXO
            search(selected: selected + [sorted[index]], index: index + 1, currentValue: currentValue + sorted[index].amount, remainingValue: remainingValue)

            // Branch 2: Exclude current UTXO
            search(selected: selected, index: index + 1, currentValue: currentValue, remainingValue: remainingValue)
        }

        search(selected: [], index: 0, currentValue: 0, remainingValue: sorted.sum(by: \.amount))

        guard !bestSelection.isEmpty else {
            throw Error.unableToFindSuitableUTXOs
        }

        return .init(outputs: bestSelection, transactionSize: bestTransactionSize, change: bestChange, fee: bestFee)
    }

    private func calculateTransactionSize(inputs: Int, outputs: Int) -> Int {
        Constants.headerSize + (inputs * Constants.inputSize) + (outputs * Constants.outputSize)
    }

    /// Calculate effective value of UTXO (value minus the cost to spend it)
    private func effectiveValue<Output: SelectableUnspentOutput>(output: Output, feeRate: UInt64) -> Int {
        let inputCost = Constants.inputSize * Int(feeRate)
        return Int(output.amount) - inputCost
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

    struct SuggestedResult<Output: SelectableUnspentOutput> {
        let outputs: [Output]
        let transactionSize: Int
        let change: UInt64
        let fee: UInt64
    }

    enum UTXOSelectionAlgorithm {
        /// Branch and Bound
        /// https://github.com/jessedegans/CoinSelectOptimized
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
        case unableToFindSuitableUTXOs
    }
}

extension ScriptUnspentOutput: UTXOSelector.SelectableUnspentOutput {}
extension UnspentOutput: UTXOSelector.SelectableUnspentOutput {}
