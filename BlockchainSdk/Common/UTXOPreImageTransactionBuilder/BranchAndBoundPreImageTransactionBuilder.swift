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
    func preImage(outputs: [ScriptUnspentOutput], changeScript: UTXOScriptType, destination: UTXOPreImageDestination, fee: Fee) throws -> UTXOPreImageTransaction {
        if Thread.isMainThread {
            BSDKLogger.warning("Don't call this method from the main thread")
        }

        guard destination.amount > 0 else {
            throw Error.wrongAmount
        }

        guard fee.isCalculation || destination.amount > calculator.dust(type: destination.script) else {
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
        let context = Context(changeScript: changeScript, destination: destination, fee: fee, allOutputsCount: outputs.count)

        let startDate = Date()
        logger.debug("Start selection")
        let bestVariant = try select(in: context, sorted: sorted)
        logger.debug("End selection done with: \(Date.now.timeIntervalSince(startDate)) sec")

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
        let total = try inputs.sumReportingOverflow(by: \.amount)
        var stack: [State] = [State(selected: [], index: 0, remaining: Int(total), currentValue: 0)]

        while !stack.isEmpty {
            let state = stack.removeLast()
            tries += 1

            // Stop if we reach tries limit
            if tries >= Constants.maxTries {
                break
            }

            let variants = variantBuilders
                .compactMap { try? $0.variant(in: context, selected: state.selected, currentValue: state.currentValue) }
                .sorted(by: { compare(in: context, transaction: $0, with: $1) })

            if let variant = variants.first {
                // If variant is better then use it as the best
                if bestVariant == nil || compare(in: context, transaction: variant, with: bestVariant!) {
                    bestVariant = variant
                    logger.debug("The best variant was updated to \(variant)")
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

    func compare(in context: Context, transaction: UTXOPreImageTransaction, with other: UTXOPreImageTransaction) -> Bool {
        // Main priority to reduce the fee
        switch transaction.fee {
        // If fee is less then return true
        case ..<other.fee:
            return true

        // If fee is same then compare change
        // If we use the exactly fee we will not compare the change
        // as this may affect the transaction and lead to the "not enough fee" error
        case other.fee where context.fee.isCalculation:
            // Select with less change
            return transaction.change < other.change

        default:
            return false
        }
    }

    /// Use a stack to store and use an iterative approach
    struct State {
        let selected: [Input]
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
                selected: selected + [currentInput],
                index: index + 1,
                remaining: remaining,
                currentValue: currentValue + Int(currentInput.amount)
            )
        }
    }
}

extension UTXOPreImageTransaction: CustomStringConvertible {
    var description: String {
        [
            "outputs": "\(outputs.map { $0.amount })",
            "destination": destination.description,
            "change": change.description,
            "fee": fee.description,
        ].description
    }
}

private extension BranchAndBoundPreImageTransactionBuilder {
    struct Context {
        let changeScript: UTXOScriptType
        let destination: UTXOPreImageDestination
        let fee: UTXOPreImageTransactionBuilderFee
        let allOutputsCount: Int
    }

    private enum Constants {
        static let maxTries: Int = 100_000
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

            // Skip validation it's isCalculation and
            // We spend all outputs and fee calculation
            if context.fee.isCalculation, inputs.count == context.allOutputsCount {
                // The change may be negative value
                change -= fee

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
