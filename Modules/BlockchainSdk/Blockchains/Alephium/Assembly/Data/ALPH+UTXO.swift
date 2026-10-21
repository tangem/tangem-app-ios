//
//  ALPH+UTXO.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BigInt

extension ALPH {
    // MARK: - Asset Order Protocol

    protocol AssetOrder {}

    // MARK: - Asset Ordering Implementations

    struct AssetAscendingOrder: AssetOrder {}

    // MARK: - Selection Models

    struct Selected {
        let assets: [AssetOutputInfo]
        let gas: GasBox
    }

    // MARK: - Gas Models

    struct ProvidedGas {
        let gasOpt: GasBox
        let gasPrice: GasPrice
        let gasEstimationMultiplier: GasEstimationMultiplier?
    }

    // MARK: - Asset Models

    struct AssetAmounts {
        let alph: U256
        let tokens: [(TokenId, U256)]
    }

    // MARK: - Build Models

    struct Build {
        let providedGas: ProvidedGas
        private let ascendingOrderSelector: BuildWithOrder

        init(providedGas: ProvidedGas) {
            self.providedGas = providedGas
            ascendingOrderSelector = BuildWithOrder(providedGas: providedGas, assetOrder: AssetAscendingOrder())
        }

        func select(amounts: AssetAmounts, utxos: [AssetOutputInfo]) throws -> Selected {
            let gasPrice = providedGas.gasPrice
            let gas = providedGas.gasOpt
            let transactionFeeAmount = (gasPrice * gas).v

            let selectedAssets = try ALPH.SelectUtils().getMinimumRequiredUTXOsToSend(
                unspentOutputs: utxos,
                transactionAmount: amounts.alph.v,
                transactionFeeAmount: transactionFeeAmount,
                dustValue: ALPH.Constants.dustAmountValue,
                unspentToAmount: { $0.output.amount.v.decimal ?? .zero }
            ).get()

            return Selected(assets: selectedAssets, gas: gas)
        }
    }

    struct BuildWithOrder {
        let providedGas: ProvidedGas
        let assetOrder: AssetOrder
    }
}

extension ALPH {
    struct SelectUtils {
        /// Collects the minimum required UTXOs for a transaction (amount + fee), using a binary search approach.
        /// - Parameters:
        ///   - unspentOutputs: The list of UTXOs to select from.
        ///   - transactionAmount: The requested transaction amount.
        ///   - transactionFeeAmount: The requested transaction fee.
        ///   - dustValue: The minimum allowed change (dust threshold), or nil to ignore.
        ///   - unspentToAmount: Closure mapping a UTXO to its amount (as Decimal).
        /// - Returns: Result with selected UTXOs sorted by descending amount, or an error if dust change cannot be avoided.
        func getMinimumRequiredUTXOsToSend<T>(
            unspentOutputs: [T],
            transactionAmount: BigUInt,
            transactionFeeAmount: BigUInt,
            dustValue: Decimal?,
            unspentToAmount: (T) -> Decimal
        ) -> Result<[T], UTXOSelectionError> {
            let amount: Decimal = (transactionAmount + transactionFeeAmount).decimal ?? .zero
            let totalAvailable = unspentOutputs.reduce(Decimal(0)) { $0 + unspentToAmount($1) }

            // Insufficient balance: return all sorted descending
            if totalAvailable < amount {
                let sorted = unspentOutputs.sorted { unspentToAmount($0) > unspentToAmount($1) }
                return .success(sorted)
            }

            // Sort ascending for binary search
            var unusedSortedUnspent = unspentOutputs.sorted { unspentToAmount($0) < unspentToAmount($1) }
            var outputsRes: [T] = []
            var currentTotal = Decimal(0)

            // Select UTXOs using binary search for closest to remaining amount
            while currentTotal < amount, !unusedSortedUnspent.isEmpty {
                let target = amount - currentTotal
                let binRes = binarySearchByAmount(unusedSortedUnspent, target: target, unspentToAmount: unspentToAmount)
                let utxoIndex = getUtxoIndex(binRes: binRes, size: unusedSortedUnspent.count)
                let utxo = unusedSortedUnspent[utxoIndex]
                currentTotal += unspentToAmount(utxo)
                outputsRes.append(utxo)
                unusedSortedUnspent.remove(at: utxoIndex)
            }

            // Check for dust change
            let change = currentTotal - amount
            if change != 0, let dust = dustValue, change < dust {
                guard let utxo = unusedSortedUnspent.first else {
                    return .failure(.dustChangeError)
                }
                currentTotal += unspentToAmount(utxo)
                outputsRes.append(utxo)
                unusedSortedUnspent.removeFirst()
            }

            // Return descending by amount
            let sortedRes = outputsRes.sorted { unspentToAmount($0) > unspentToAmount($1) }
            return .success(sortedRes)
        }

        /// Binary search for the index of the UTXO closest to the target amount.
        /// Returns the index if found, or the insertion index (as negative) if not found.
        private func binarySearchByAmount<T>(
            _ array: [T],
            target: Decimal,
            unspentToAmount: (T) -> Decimal
        ) -> Int {
            var low = 0
            var high = array.count - 1
            while low <= high {
                let mid = (low + high) / 2
                let value = unspentToAmount(array[mid])
                if value == target {
                    return mid
                } else if value < target {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            // Not found: return insertion point as negative
            return -(low + 1)
        }

        /// Helper to get the correct UTXO index from binary search result.
        private func getUtxoIndex(binRes: Int, size: Int) -> Int {
            if binRes < 0 {
                let possibleIndex = -binRes - 1
                return possibleIndex == size ? possibleIndex - 1 : possibleIndex
            } else {
                return binRes
            }
        }
    }

    /// Error types for UTXO selection.
    enum UTXOSelectionError: Error {
        case invalidAmount
        case dustChangeError
    }
}
