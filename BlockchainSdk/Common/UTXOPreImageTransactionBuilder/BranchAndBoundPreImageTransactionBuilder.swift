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
    typealias Input = ScriptUnspentOutput
    typealias Output = UTXOScriptType
    typealias Fee = UTXOPreImageTransactionBuilderFee
    typealias Error = UTXOPreImageTransactionBuilderError
    private let calculator: UTXOTransactionSizeCalculator
    private let variantBuilders: [TransactionVariantBuilder]

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
        guard destination.amount > 0 else {
            throw Error.wrongAmount
        }

        guard destination.amount > calculator.dust(type: destination.script) else {
            throw Error.dustAmount
        }

        guard !outputs.isEmpty else {
            throw Error.noOutputs
        }

        let total = outputs.sum(by: \.amount)
        if total < destination.amount {
            throw Error.insufficientFunds
        }

        let sorted = outputs.sorted { $0.amount > $1.amount }
        let context = Context(changeScript: changeScript, destination: destination, fee: fee, allOutputsCount: outputs.count)
        return try select(in: context, sorted: sorted)
    }
}

// MARK: - Private

extension BranchAndBoundPreImageTransactionBuilder {
    private func select(in context: Context, sorted inputs: [Input]) throws -> UTXOPreImageTransaction {
        var bestVariant: UTXOPreImageTransaction?
        var tries = 0

        func search(selected: [Input], index: Int) {
            tries += 1

            // Stop if we reach tries limit
            if tries > Constants.maxTries {
                return
            }

            let currentValue = Int(selected.sum(by: \.amount))
            let variants = variantBuilders
                .compactMap { try? $0.variant(in: context, selected: selected, currentValue: currentValue) }
                .sorted(by: { $0.better(than: $1) })

            if let variant = variants.first {
                // If variant is better then use it as the best
                if bestVariant == nil || variant.better(than: bestVariant!) {
                    bestVariant = variant
                    BSDKLogger.tag("PreImageTxBuilder").debug("The best variant was updated to \(variant)")
                }
            }

            // Stop if we reach last element
            if index >= inputs.count {
                return
            }

            // Branch 1: Include current UTXO
            search(selected: selected + [inputs[index]], index: index + 1)

            // Branch 2: Exclude current UTXO
            search(selected: selected, index: index + 1)
        }

        search(selected: [], index: 0)

        guard let bestVariant, !bestVariant.outputs.isEmpty else {
            throw Error.unableToFindSuitableUTXOs
        }

        return bestVariant
    }
}

private extension UTXOPreImageTransaction {
    func better(than transaction: UTXOPreImageTransaction) -> Bool {
        // Main priority to reduce the fee
        switch fee {
        // If fee is less then return true
        case ..<transaction.fee:
            return true

        // If fee is same then compare change
        case transaction.fee:
            // Select with less change
            return change < transaction.change

        default:
            return false
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
            let size = calculator.transactionSize(inputs: inputs, outputs: outputs)
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
            guard change == 0 || change > calculator.dust(type: context.changeScript) else {
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

            var (size, fee) = try proceedFee(in: context, change: change, inputs: inputs, outputs: outputs)
            change -= fee

            // Check that change is too small
            // We have to be sure that change output don't needed
            guard change < calculator.dust(type: context.changeScript) else {
                throw VariantError.changeIsEnough
            }

            // add dust to recipientValue to avoid dust error
            if change > 0 {
                fee += change
            }

            return UTXOPreImageTransaction(outputs: inputs, destination: recipientValue, change: 0, fee: fee, size: size)
        }

        private func proceedFee(in context: Context, change: Int, inputs: [Input], outputs: [Output]) throws -> (size: Int, fee: Int) {
            let size = calculator.transactionSize(inputs: inputs, outputs: outputs)

            // Calculation fee with spending all outputs -> skip validation
            // Use exactly fee -> Validate
            // Calculation fee with using not all outputs -> Validate(to skip case when outputs is not enough for fee)
            switch context.fee {
            case .calculate(let feeRate):
                let fee = size * feeRate

                // Skip validation if spend all outputs and fee calculation
                let isSpendAll = inputs.count == context.allOutputsCount
                guard isSpendAll || change >= fee else {
                    throw VariantError.notEnoughForFee
                }

                return (size: size, fee: fee)
            case .exactly(let fee):
                guard change >= fee else {
                    throw VariantError.notEnoughForFee
                }

                return (size: size, fee: fee)
            }
        }
    }
}
