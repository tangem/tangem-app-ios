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

    func selectOutputs(amount: Decimal, fee: Decimal) throws -> [ScriptUnspentOutput] {
        let dust = (0.0001 * decimalValue).uint64Value
        let amount = (amount * decimalValue).uint64Value
        let fee = (fee * decimalValue).uint64Value
        let selector = UTXOSelector(dustThreshold: dust)
        let selected: [ScriptUnspentOutput] = try selector.select(outputs: allOutputs(), amount: amount, fee: fee)

        return selected
    }

    func confirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { $0.isConfirmed }.reduce(0) { $0 + $1.amount }
    }

    func unconfirmedBalance() -> UInt64 {
        outputs.read().flatMap { $0.value }.filter { !$0.isConfirmed }.reduce(0) { $0 + $1.amount }
    }
}

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

protocol SelectableUnspentOutput {
    var amount: UInt64 { get }
}

struct UTXOSelector {
    let dustThreshold: UInt64

    /// Минимальный порог "пыли" в сатоши
    init(dustThreshold: UInt64 = 546) {
        self.dustThreshold = dustThreshold
    }

    func select<Output: SelectableUnspentOutput>(outputs: [Output], amount: UInt64, fee: UInt64, algorithm: UTXOSelectionAlgorithm = .bnb) throws -> [Output] {
        guard amount > 0 else {
            throw Error.wrongAmount
        }

        guard !outputs.isEmpty else {
            throw Error.noOutputs
        }

        let total = outputs.sum(by: \.amount)
        if total < amount + fee {
            throw Error.insufficientFunds
        }

        let sorted = outputs.sorted { $0.amount > $1.amount }

        switch algorithm {
        case .bnb:
            return try bnbSelect(sorted: sorted, targetValue: amount + fee)
        case .binary:
            return try binarySelect(sorted: sorted, targetValue: amount + fee)
        }
    }

    private func binarySelect<Output: SelectableUnspentOutput>(sorted: [Output], targetValue amount: UInt64) throws -> [Output] {
        var left = 0
        var right = sorted.count - 1
        var best: [Output]?

        while left <= right {
            let mid = (left + right) / 2
            let candidate = Array(sorted[mid...])
            let candidateSum = candidate.sum(by: \.amount)

            if candidateSum >= amount {
                best = candidate
                right = mid - 1
            } else {
                left = mid + 1
            }
        }

        guard var bestMatch = best else {
            throw Error.unableToFindSuitableUTXOs
        }

        let spend = bestMatch.sum(by: \.amount)
        let change = spend - amount
        if change > 0, change < dustThreshold {
            // Check if resulting spending UTXOs leads to output UTXO having amount less than dust.
            // In that case add smallest UTXO so output UTXO was greater than dust.
            sorted.last.map { bestMatch.append($0) }
        }

        return bestMatch
    }

    private func bnbSelect<Output: SelectableUnspentOutput>(sorted: [Output], targetValue: UInt64) throws -> [Output] {
        var bestSelection: [Output]?
        var bestChange: UInt64 = .max
        var bestCount: Int = sorted.count
        var tries = 0

        func search(selected: [Output], index: Int, currentValue: UInt64, remainingValue: UInt64) {
            tries += 1
            if tries > Constants.maxTries { return }

            // If we found enough outputs to cover target amount
            if currentValue >= targetValue {
                let currentCount = selected.count
                let currentChange = currentValue - targetValue

                let changeIsAcceptable = currentChange >= 0 || currentChange >= dustThreshold && currentChange < bestChange
                let countIsAcceptable = selected.count <= bestCount

                if bestSelection == nil || changeIsAcceptable, countIsAcceptable {
                    bestSelection = selected
                    bestChange = currentChange
                    bestCount = currentCount
                }

                return
            }

            // Reach last element
            // Stop if we can't reach the target with remaining UTXOs
            if index >= sorted.count || currentValue + remainingValue < targetValue { return }

            let remainingValue = remainingValue - sorted[index].amount
            // Branch 1: Include current UTXO
            search(selected: selected + [sorted[index]], index: index + 1, currentValue: currentValue + sorted[index].amount, remainingValue: remainingValue)

            // Branch 2: Exclude current UTXO
            search(selected: selected, index: index + 1, currentValue: currentValue, remainingValue: remainingValue)
        }

        search(selected: [], index: 0, currentValue: 0, remainingValue: sorted.sum(by: \.amount))

        guard let bestSelection else {
            throw Error.unableToFindSuitableUTXOs
        }

        return bestSelection
    }

//    private func calculateFee(selected: Int, feeRate: Int) -> Int {
//        selected * Constants.inputSize * feeRate
//    }
}

extension UTXOSelector {
    enum Constants {
        /// Average input size in bytes
        static let inputSize: Int = 148
        /// Average output size in bytes
        static let outputSize: Int64 = 34
        /// Transaction header size in bytes
        static let headerSize: Int64 = 10

        static let maxTries: Int = 100_000
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

extension ScriptUnspentOutput: SelectableUnspentOutput {}
