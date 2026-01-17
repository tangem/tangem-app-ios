//
//  CommonExpressTokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine
import TangemFoundation

class CommonExpressTokenFeeProvidersManager {
    private let tokenItem: TokenItem
    private let tokenFeeManagerBuilder: TokenFeeProvidersManagerBuilder

    private let managers: ThreadSafeContainer<[ExpressProvider.Id: TokenFeeProvidersManager]> = [:]

    init(tokenItem: TokenItem, tokenFeeManagerBuilder: TokenFeeProvidersManagerBuilder) {
        self.tokenItem = tokenItem
        self.tokenFeeManagerBuilder = tokenFeeManagerBuilder
    }
}

// MARK: - ExpressTokenFeeProvidersManager

extension CommonExpressTokenFeeProvidersManager: ExpressTokenFeeProvidersManager {
    func tokenFeeProvidersManager(providerId: ExpressProvider.Id) -> TokenFeeProvidersManager {
        if let feeManager = managers[providerId] {
            return feeManager
        }

        let feeManager = tokenFeeManagerBuilder.makeTokenFeeProvidersManager()
        managers.mutate { $0[providerId] = feeManager }

        return feeManager
    }

    func updateSelectedFeeOptionInAllManagers(feeOption: FeeOption) {
        managers.values.forEach { tokenFeeProvidersManager in
            tokenFeeProvidersManager.updateFeeOptionInAllProviders(feeOption: feeOption)
        }
    }

    func updateSelectedFeeTokenItemInAllManagers(feeTokenItem: TokenItem) {
        managers.values.forEach { tokenFeeProvidersManager in
            tokenFeeProvidersManager.updateSelectedFeeProvider(feeTokenItem: feeTokenItem)
            tokenFeeProvidersManager.selectedFeeProvider.updateFees()
        }
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressTokenFeeProvidersManager: ExpressFeeProvider {
    func estimatedFee(request: FeeRequest, amount: Decimal) async throws -> BSDKFee {
        let feeManager = tokenFeeProvidersManager(providerId: request.provider.id)
        feeManager.updateInputInAllProviders(input: .cex(amount: amount))
        await feeManager.selectedFeeProvider.updateFees().value

        let fee = try feeManager.selectedFeeProvider.selectedTokenFee.value.get()
        return fee
    }

    func estimatedFee(request: FeeRequest, estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee {
        let feeManager = tokenFeeProvidersManager(providerId: request.provider.id)
        feeManager.updateInputInAllProviders(
            input: .dex(.ethereumEstimate(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee))
        )
        await feeManager.selectedFeeProvider.updateFees().value

        let fee = try feeManager.selectedFeeProvider.selectedTokenFee.value.get()
        return fee
    }

    func transactionFee(request: FeeRequest, data: ExpressTransactionDataType) async throws -> BSDKFee {
        let feeManager = tokenFeeProvidersManager(providerId: request.provider.id)

        switch (data, tokenItem.blockchain) {
        case (.cex(let data), _):
            feeManager.updateInputInAllProviders(
                input: .common(amount: data.fromAmount, destination: data.destinationAddress)
            )
            await feeManager.selectedFeeProvider.updateFees().value

            let fee = try feeManager.selectedFeeProvider.selectedTokenFee.value.get()
            return fee

        case (.dex(let data), .solana):
            guard let txData = data.txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            feeManager.updateInputInAllProviders(input: .dex(.solana(compiledTransaction: transactionData)))
            await feeManager.selectedFeeProvider.updateFees().value

            let fee = try feeManager.selectedFeeProvider.selectedTokenFee.value.get()
            return fee

        case (.dex(let data), _):
            guard let txData = data.txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            // The `txValue` is always is coin
            let amount = BSDKAmount(with: tokenItem.blockchain, type: .coin, value: data.txValue)
            feeManager.updateInputInAllProviders(input: .dex(.ethereum(
                amount: amount,
                destination: data.destinationAddress,
                txData: txData,
                otherNativeFee: data.otherNativeFee
            )))

            await feeManager.selectedFeeProvider.updateFees().value
            let fee = try feeManager.selectedFeeProvider.selectedTokenFee.value.get()

            return fee
        }
    }
}
