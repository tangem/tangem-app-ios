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

    protocol AssetOrder {
        func byAlph(_ x: AssetOutputInfo, _ y: AssetOutputInfo) -> Bool
        func byToken(id: TokenId) -> (AssetOutputInfo, AssetOutputInfo) -> Bool
    }

    // MARK: - Asset Ordering Implementations

    struct AssetAscendingOrder: AssetOrder {
        func byAlph(_ x: AssetOutputInfo, _ y: AssetOutputInfo) -> Bool {
            if x.outputType.cachedLevel != y.outputType.cachedLevel {
                return x.outputType.cachedLevel < y.outputType.cachedLevel
            }
            return x.output.amount < y.output.amount
        }

        func byToken(id: TokenId) -> (AssetOutputInfo, AssetOutputInfo) -> Bool {
            return { x, y in
                let compare1 = x.outputType.cachedLevel - y.outputType.cachedLevel

                let tokenX = x.output.tokens.first(where: { $0.0.value == id.value })
                let tokenY = y.output.tokens.first(where: { $0.0.value == id.value })

                if let tokenX = tokenX, let tokenY = tokenY {
                    if compare1 != 0 { return compare1 < 0 }
                    if tokenX.1 != tokenY.1 { return tokenX.1 < tokenY.1 }
                    return byAlph(x, y)
                }
                return tokenX != nil ? true : tokenY == nil ? byAlph(x, y) : false
            }
        }
    }

    struct AssetDescendingOrder: AssetOrder {
        let ascending = AssetAscendingOrder()

        func byAlph(_ x: AssetOutputInfo, _ y: AssetOutputInfo) -> Bool {
            return !ascending.byAlph(x, y)
        }

        func byToken(id: TokenId) -> (AssetOutputInfo, AssetOutputInfo) -> Bool {
            return { x, y in
                !ascending.byToken(id: id)(x, y)
            }
        }
    }

    // MARK: - Selection Models

    struct Selected {
        let assets: [AssetOutputInfo]
        let gas: GasBox
    }

    struct SelectedSoFar {
        let alph: U256
        let selected: [AssetOutputInfo]
        let rest: [AssetOutputInfo]
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

    struct TxInputWithAsset {
        let input: TxInputInfo
        let asset: AssetOutputInfo

        static func from(asset: AssetOutputInfo, unlockScript: UnlockScript) -> TxInputWithAsset {
            return TxInputWithAsset(input: TxInputInfo(outputRef: asset.ref, unlockScript: unlockScript), asset: asset)
        }
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
            try ascendingOrderSelector.select(amounts: amounts, utxos: utxos)
        }
    }

    struct BuildWithOrder {
        let providedGas: ProvidedGas
        let assetOrder: AssetOrder

        func select(amounts: AssetAmounts, utxos: [AssetOutputInfo]) throws -> Selected {
            let gasAmount = providedGas.gasPrice * providedGas.gasOpt
            let amountsWithGas = AssetAmounts(alph: amounts.alph.addUnsafe(gasAmount), tokens: amounts.tokens)

            return try SelectionWithoutGasEstimation(assetOrder: assetOrder)
                .select(amounts: amountsWithGas, allUtxos: utxos)
                .map { selectedSoFar in
                    Selected(assets: selectedSoFar.selected, gas: providedGas.gasOpt)
                }.get()
        }
    }

    // MARK: - Selection Logic

    struct SelectionWithoutGasEstimation {
        let assetOrder: AssetOrder

        func select(amounts: AssetAmounts, allUtxos: [AssetOutputInfo]) -> Result<SelectedSoFar, Error> {
            do {
                let (utxosForTokens, remainingUtxos) = try selectForTokens(amounts.tokens, currentUtxos: [], restOfUtxos: allUtxos).get()

                let alphSelected = utxosForTokens.reduce(U256.zero) { $0.addUnsafe($1.output.amount) }
                let alphToSelect = amounts.alph.sub(alphSelected) ?? U256.zero

                let (utxosForAlph, restOfUtxos) = try selectForAmount(alphToSelect, sortedUtxos: sortAlph(remainingUtxos)) { $0.output.amount }.get()

                let foundUtxos = utxosForTokens + utxosForAlph
                let attoAlphAmountWithoutGas = foundUtxos.reduce(U256.zero) { $0.addUnsafe($1.output.amount) }

                return .success(SelectedSoFar(alph: attoAlphAmountWithoutGas, selected: foundUtxos, rest: restOfUtxos))
            } catch {
                return .failure(error)
            }
        }

        private func sortAlph(_ assets: [AssetOutputInfo]) -> [AssetOutputInfo] {
            let assetsWithoutTokens = assets.filter { $0.output.tokens.isEmpty }.sorted(by: assetOrder.byAlph)
            let assetsWithTokens = assets.filter { !$0.output.tokens.isEmpty }.sorted(by: assetOrder.byAlph)
            return assetsWithoutTokens + assetsWithTokens
        }

        private func selectForAmount(
            _ amount: U256,
            sortedUtxos: [AssetOutputInfo],
            getAmount: (AssetOutputInfo) -> U256
        ) -> Result<([AssetOutputInfo], [AssetOutputInfo]), Error> {
            if amount == U256.zero { return .success(([], sortedUtxos)) }

            var sum = U256.zero
            var index = -1

            for (idx, asset) in sortedUtxos.enumerated() {
                if sum >= amount { break }
                sum = sum.addUnsafe(getAmount(asset))
                index = idx
            }

            if sum < amount {
                return .failure(WalletError.failedToBuildTx)
            }

            return .success((Array(sortedUtxos.prefix(index + 1)), Array(sortedUtxos.dropFirst(index + 1))))
        }

        private func selectForTokens(
            _ totalAmountPerToken: [(TokenId, U256)],
            currentUtxos: [AssetOutputInfo],
            restOfUtxos: [AssetOutputInfo]
        ) -> Result<([AssetOutputInfo], [AssetOutputInfo]), Error> {
            guard let (tokenId, amount) = totalAmountPerToken.first else {
                return .success((currentUtxos, restOfUtxos))
            }

            let sortedUtxos = restOfUtxos.sorted(by: assetOrder.byToken(id: tokenId))
            let remainingTokenAmount = calculateRemainingTokensAmount(utxos: currentUtxos, tokenId: tokenId, amount: amount)

            let foundResult = selectForAmount(remainingTokenAmount, sortedUtxos: sortedUtxos) { asset in
                asset.output.tokens.first { $0.0.value == tokenId.value }?.1 ?? U256.zero
            }

            return foundResult.flatMap { first, second in
                selectForTokens(Array(totalAmountPerToken.dropFirst()), currentUtxos: currentUtxos + first, restOfUtxos: second)
            }
        }

        private func calculateRemainingTokensAmount(utxos: [AssetOutputInfo], tokenId: TokenId, amount: U256) -> U256 {
            let amountInUtxo = utxos.reduce(U256.zero) { acc, utxo in
                acc.addUnsafe(utxo.output.tokens.first { $0.0.value == tokenId.value }?.1 ?? U256.zero)
            }
            return amount.sub(amountInUtxo) ?? U256.zero
        }
    }
}
