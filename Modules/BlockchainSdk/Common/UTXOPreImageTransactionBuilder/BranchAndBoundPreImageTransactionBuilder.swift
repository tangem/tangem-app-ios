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
class BranchAndBoundPreImageTransactionBuilder {
    typealias Input = ScriptUnspentOutput
    typealias Output = UTXOScriptType
    typealias Fee = UTXOPreImageTransactionBuilderFee
    typealias Error = UTXOPreImageTransactionBuilderError

    private let calculator: UTXOTransactionSizeCalculator
    private let variantBuilders: [TransactionVariantBuilder]
    private let logger = BSDKLogger.tag("PreImageTxBuilder")

    init(calculator: UTXOTransactionSizeCalculator) {
        self.calculator = calculator

        variantBuilders = [
            TwoOutputTransactionVariantBuilder(calculator: calculator),
            SingleOutputTransactionVariantBuilder(calculator: calculator),
        ]
    }
}

// MARK: - UTXOPreImageTransactionBuilder

extension BranchAndBoundPreImageTransactionBuilder: UTXOPreImageTransactionBuilder {
    func preImage(outputs: [ScriptUnspentOutput], changeScript: UTXOScriptType, destination: UTXOPreImageDestination, fee: Fee) async throws -> UTXOPreImageTransaction {
        guard destination.amount > 0 else {
            throw Error.wrongAmount
        }

        guard fee.isCalculation || destination.amount >= calculator.dust(type: destination.script) else {
            throw Error.dustAmount
        }

        guard !outputs.isEmpty else {
            throw Error.noOutputs
        }

        let total = try outputs.sumReportingOverflow(by: \.amount)
        guard destination.amount <= total else {
            throw Error.insufficientFunds
        }

        let sorted = outputs.sorted { $0.amount > $1.amount }
        let context = Context(
            startDate: .now,
            changeScript: changeScript,
            destination: destination,
            fee: fee,
            totalOutputsCount: outputs.count,
            total: Int(total)
        )

        logger.debug(self, "Start selection in: \(context.startDate.formatted(date: .omitted, time: .complete))")
        let bestVariant = try select(in: context, sorted: sorted)
        logger.debug(self, "End selection done with: \(Date.now.timeIntervalSince(context.startDate)) sec with bestVariant: \(String(describing: bestVariant))")

        guard let bestVariant, !bestVariant.outputs.isEmpty else {
            throw Error.unableToFindSuitableUTXOs
        }

        return bestVariant
    }
}

// MARK: - Private

private extension BranchAndBoundPreImageTransactionBuilder {
    func select(in context: Context, sorted inputs: [Input]) throws -> UTXOPreImageTransaction? {
        var bestVariant: UTXOPreImageTransaction?
        var tries = 0
        var stack: [State] = [State(selected: [], index: 0, remaining: context.total, currentValue: 0)]

        // If we have too many inputs do not start algorithm
        if inputs.count > Constants.maxInputs {
            return try simpleSelect(in: context, sorted: inputs)
        }

        while !stack.isEmpty {
            // Check cancellation every cycle
            try Task.checkCancellation()

            // Check timeout
            if Date.now.timeIntervalSince(context.startDate) > Constants.timeout {
                logger.debug(self, "Stop selection by timeout")
                break
            }

            let state = stack.removeLast()
            tries += 1

            // Stop if we reach tries limit
            if tries >= Constants.maxTries {
                logger.debug(self, "Stop selection by max tries")
                break
            }

            let selectedInputs = state.selected.map { inputs[$0] }
            let variants = variantBuilders
                .compactMap { try? $0.variant(in: context, selected: selectedInputs, currentValue: state.currentValue) }
                .sorted(by: { $0.better(than: $1) })

            if let variant = variants.first {
                // If variant is better then use it as the best
                if bestVariant == nil || variant.better(than: bestVariant!) {
                    bestVariant = variant
                }

                // Skip further processing for this branch
                continue
            }

            // If we reach last element, cut the branch
            if state.index >= inputs.count {
                continue
            }

            // If we can't possibly reach destination amount, cut the branch
            if state.currentValue + state.remaining < context.destination.amount {
                continue
            }

            // Branch 1: Exclude current UTXO (push first to process include branch first)
            stack.append(state.excludeCurrent(inputs: inputs))

            // Branch 2: Include current UTXO
            stack.append(state.includeCurrent(inputs: inputs))
        }

        return bestVariant
    }

    func simpleSelect(in context: Context, sorted inputs: [Input]) throws -> UTXOPreImageTransaction? {
        guard let (selectedIndices, value) = simpleSelection(from: inputs, target: context.destination.amount) else {
            return nil
        }

        let selectedInputs = selectedIndices.map { inputs[$0] }
        let variants = variantBuilders
            .compactMap { try? $0.variant(in: context, selected: selectedInputs, currentValue: value) }
            .sorted(by: { $0.better(than: $1) })

        return variants.first
    }

    func simpleSelection(from inputs: [Input], target: Int) -> (selected: [Int], value: Int)? {
        var sum = 0
        var selected: [Int] = []

        for (index, input) in inputs.enumerated() {
            selected.append(index)
            sum += Int(input.amount)

            if sum >= target {
                return (selected: selected, value: sum)
            }
        }

        return nil
    }

    /// Use a stack to store and use an iterative approach
    struct State {
        let selected: [Int]
        let index: Int
        let remaining: Int
        let currentValue: Int

        func excludeCurrent(inputs: [Input]) -> State {
            let remaining = remaining - Int(inputs[index].amount)

            return State(
                selected: selected,
                index: index + 1,
                remaining: remaining,
                currentValue: currentValue
            )
        }

        func includeCurrent(inputs: [Input]) -> State {
            let currentInput = inputs[index]
            return State(
                selected: selected + [index],
                index: index + 1,
                remaining: remaining,
                currentValue: currentValue + Int(currentInput.amount)
            )
        }
    }
}

// MARK: - CustomStringConvertible

extension BranchAndBoundPreImageTransactionBuilder: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

private extension UTXOPreImageTransaction {
    func better(than transaction: UTXOPreImageTransaction) -> Bool {
        switch size {
        // Main priority to reduce the size
        case ..<transaction.size: return true

        // If size is same then compare change
        // Select with less change
        case transaction.size:
            return change < transaction.change

        default:
            return false
        }
    }
}

extension UTXOPreImageTransaction: CustomStringConvertible {
    var description: String {
        [
            "destination": destination.description,
            "change": change.description,
            "fee": fee.description,
            "outputs_count": outputs.count,
            "outputs_sum": outputs.sum(by: \.amount),
        ].sorted(by: { $0.key > $1.key }).description
    }
}

private extension BranchAndBoundPreImageTransactionBuilder {
    struct Context {
        let startDate: Date
        let changeScript: UTXOScriptType
        let destination: UTXOPreImageDestination
        let fee: UTXOPreImageTransactionBuilderFee
        let totalOutputsCount: Int
        let total: Int
    }

    private enum Constants {
        static let maxInputs: Int = 1000
        static let maxTries: Int = 100_000
        static let timeout: TimeInterval = 30
    }

    private enum VariantError: LocalizedError {
        case notEnough
        case notEnoughForFee
        case notEnoughForDustThreshold
        case changeIsEnough
    }
}

// MARK: - TransactionVariantBuilder

private extension BranchAndBoundPreImageTransactionBuilder {
    protocol TransactionVariantBuilder {
        func variant(in context: Context, selected inputs: [Input], currentValue: Int) throws -> UTXOPreImageTransaction
    }

    /// Two outputs - Destination and Change
    struct TwoOutputTransactionVariantBuilder: TransactionVariantBuilder {
        let calculator: UTXOTransactionSizeCalculator

        func variant(in context: Context, selected inputs: [Input], currentValue: Int) throws -> UTXOPreImageTransaction {
            let recipientValue = context.destination.amount

            // 1. We have enough to send without fee is exist
            guard currentValue >= recipientValue else {
                throw VariantError.notEnough
            }

            var change = currentValue - recipientValue
            let outputs: [UTXOScriptType] = [context.changeScript, context.destination.script]

            // 2. Proceed fee
            let size = try calculator.transactionSize(inputs: inputs, outputs: outputs)
            let fee = switch context.fee {
            case .calculate(let feeRate): size * feeRate
            case .exactly(let fee): fee
            }

            // In two outputs builder we always validate fee
            guard change >= fee else {
                throw VariantError.notEnoughForFee
            }

            change -= fee

            // Skip validation if we all outputs and fee calculation
            if context.fee.isCalculation, inputs.count == context.totalOutputsCount {
                return UTXOPreImageTransaction(outputs: inputs, destination: recipientValue, change: change, fee: fee, size: size)
            }

            // 3. Remaining change is enough to cover dust threshold
            guard change == 0 || change >= calculator.dust(type: context.changeScript) else {
                throw VariantError.notEnoughForDustThreshold
            }

            return UTXOPreImageTransaction(outputs: inputs, destination: recipientValue, change: change, fee: fee, size: size)
        }
    }

    /// Only one output - Destination
    struct SingleOutputTransactionVariantBuilder: TransactionVariantBuilder {
        let calculator: UTXOTransactionSizeCalculator

        func variant(in context: Context, selected inputs: [Input], currentValue: Int) throws -> UTXOPreImageTransaction {
            let recipientValue = context.destination.amount

            // Possible value to cover fee
            guard currentValue >= recipientValue else {
                throw VariantError.notEnough
            }

            var change = currentValue - recipientValue
            let outputs: [UTXOScriptType] = [context.destination.script]

            let size = try calculator.transactionSize(inputs: inputs, outputs: outputs)
            let fee = switch context.fee {
            case .calculate(let feeRate): size * feeRate
            case .exactly(let fee): fee
            }

            // If all known inputs are selected, allow single-output variant even when fee
            // consumes the remainder (or makes effective change negative).
            if context.fee.isCalculation, inputs.count == context.totalOutputsCount {
                change -= fee

                guard change <= 0 else {
                    throw VariantError.changeIsEnough
                }

                return UTXOPreImageTransaction(outputs: inputs, destination: recipientValue, change: change, fee: fee, size: size)
            }

            guard change <= fee else {
                throw VariantError.notEnoughForFee
            }

            change -= fee

            // Remaining change should be 0
            guard change == 0 else {
                throw VariantError.changeIsEnough
            }

            return UTXOPreImageTransaction(outputs: inputs, destination: recipientValue, change: change, fee: fee, size: size)
        }
    }
}
