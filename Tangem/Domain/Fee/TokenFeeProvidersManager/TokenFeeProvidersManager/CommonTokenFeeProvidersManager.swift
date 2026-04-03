//
//  CommonTokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemExpress
import TangemFoundation

final class CommonTokenFeeProvidersManager {
    private let feeProviders: [any TokenFeeProvider]
    private let initialSelectedProvider: any TokenFeeProvider

    private let selectedProviderSubject: CurrentValueSubject<any TokenFeeProvider, Never>

    init(
        feeProviders: [any TokenFeeProvider],
        initialSelectedProvider: any TokenFeeProvider
    ) {
        self.feeProviders = feeProviders
        self.initialSelectedProvider = initialSelectedProvider

        selectedProviderSubject = .init(initialSelectedProvider)
    }
}

// MARK: - TokenFeeProvidersManager

extension CommonTokenFeeProvidersManager: TokenFeeProvidersManager {
    var selectedFeeProvider: any TokenFeeProvider {
        selectedProviderSubject.value
    }

    var selectedFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> {
        selectedProviderSubject.eraseToAnyPublisher()
    }

    var tokenFeeProviders: [any TokenFeeProvider] {
        feeProviders
    }

    var supportFeeSelection: Bool {
        let hasMultipleFeeProviders = feeProviders.hasMultipleFeeProviders
        let selectedHasMultipleOptions = selectedFeeProvider.hasMultipleFeeOptions
        let selectedHasTokenBalance = !selectedFeeProvider.state.isUnavailableNoTokenBalance

        return hasMultipleFeeProviders || (selectedHasMultipleOptions && selectedHasTokenBalance)
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        let hasMultipleSupportedProviders = Publishers.MergeMany(feeProviders.map { $0.statePublisher })
            .map { [feeProviders] _ in feeProviders.hasMultipleFeeProviders }

        return Publishers.CombineLatest3(
            selectedFeeProviderPublisher.map(\.hasMultipleFeeOptions),
            hasMultipleSupportedProviders,
            selectedFeeProviderPublisher.flatMapLatest { $0.statePublisher.map(\.isUnavailableNoTokenBalance) }
        )
        .map { hasMultipleOptions, hasMultipleProviders, noTokenBalance in
            hasMultipleProviders || (hasMultipleOptions && !noTokenBalance)
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }

    // Updating

    func update(feeOption: FeeOption) {
        feeProviders.forEach { $0.select(feeOption: feeOption) }
    }

    func update(input: TokenFeeProviderInputData) {
        feeProviders.forEach { $0.setup(input: input) }

        checkSelectedProviderIsSupported()
    }

    @discardableResult
    func updateFees() -> Task<Void, Never> {
        return Task { [weak self] in
            await self?.selectedFeeProvider.updateFees().value
            await self?.switchToProviderWithEnoughBalanceIfNeeded()
        }
    }

    func updateSelectedFeeProvider(feeTokenItem: TokenItem) {
        guard let tokenFeeProvider = feeProviders.first(where: { $0.feeTokenItem == feeTokenItem }) else {
            FeeLogger.error(self, error: "Provider for token item \(feeTokenItem.name) not found")
            return
        }

        guard tokenFeeProvider.state.isSupported else {
            FeeLogger.info(self, "Provider for token item \(feeTokenItem.name) is not supported. Will not select")
            return
        }

        guard tokenFeeProvider.feeTokenItem != selectedFeeProvider.feeTokenItem else {
            FeeLogger.info(self, "Try to select already selected provider with token item \(feeTokenItem.name). Will not select")
            return
        }

        FeeLogger.info(self, "Update selected provider to token item \(tokenFeeProvider)")
        selectedProviderSubject.send(tokenFeeProvider)
    }
}

// MARK: - ExpressFeeProvider

extension CommonTokenFeeProvidersManager: ExpressFeeProvider {
    func feeCurrency() -> ExpressWalletCurrency {
        selectedFeeProvider.feeTokenItem.expressCurrency
    }

    func feeCurrencyBalance() throws -> Decimal {
        guard let balance = selectedFeeProvider.balanceFeeTokenState.value else {
            throw ExpressBalanceProviderError.balanceNotFound
        }

        return balance
    }

    func estimatedFee(amount: Decimal) async throws -> BSDKFee {
        update(input: .cex(amount: amount))
        await updateFees().value

        let fee = try selectedFeeProvider.selectedTokenFee.value.get()
        return fee
    }

    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee {
        update(
            input: .dex(.ethereumEstimate(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee))
        )

        await updateFees().value
        let fee = try selectedFeeProvider.selectedTokenFee.value.get()

        return fee
    }

    func transactionFee(txData: Data, toContractAddress: String) async throws -> BSDKFee {
        update(input: .approve(txData: txData, toContractAddress: toContractAddress))
        await updateFees().value
        let fee = try selectedFeeProvider.selectedTokenFee.value.get()
        return fee
    }

    func transactionFee(data: ExpressTransactionDataType) async throws -> BSDKFee {
        let blockchain = initialSelectedProvider.feeTokenItem.blockchain

        switch (data, blockchain) {
        case (.cex(let data), _):
            update(
                input: .common(amount: data.fromAmount, destination: data.destinationAddress)
            )

            await updateFees().value
            let fee = try selectedFeeProvider.selectedTokenFee.value.get()

            return fee

        case (.dex(let data), .solana):
            guard let txData = data.txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            update(input: .dex(.solana(compiledTransaction: transactionData)))
            await updateFees().value
            let fee = try selectedFeeProvider.selectedTokenFee.value.get()

            return fee

        case (.dex(let data), _):
            guard let txData = data.txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            // The `txValue` is always is coin
            let amount = BSDKAmount(with: blockchain, type: .coin, value: data.txValue)
            update(input: .dex(.ethereum(
                amount: amount,
                destination: data.destinationAddress,
                txData: txData,
                otherNativeFee: data.otherNativeFee
            )))

            await updateFees().value
            let fee = try selectedFeeProvider.selectedTokenFee.value.get()

            return fee
        }
    }
}

// MARK: - Private

private extension CommonTokenFeeProvidersManager {
    func switchToProviderWithEnoughBalanceIfNeeded() async {
        guard let feeAmount = selectedFeeProvider.selectedTokenFee.value.value?.amount.value,
              let balance = selectedFeeProvider.balanceFeeTokenState.loaded else {
            return
        }

        guard feeAmount > balance else {
            return
        }

        FeeLogger.info(self, "Detect that selected provider doesn't have enough balance to cover fee")
        let idleTokenFeeProvider = tokenFeeProviders.first(where: { $0.state.isIdle })

        guard let idleTokenFeeProvider else {
            FeeLogger.info(self, "There are no other providers to choose. Fallback to initial")
            selectedProviderSubject.send(initialSelectedProvider)
            return
        }

        updateSelectedFeeProvider(feeTokenItem: idleTokenFeeProvider.feeTokenItem)
        await updateFees().value
    }

    func checkSelectedProviderIsSupported() {
        guard !selectedFeeProvider.state.isSupported else {
            // All good
            return
        }

        guard let supportedFeeProvider = feeProviders.first(where: { $0.state.isSupported }) else {
            FeeLogger.error(self, error: "Don't have supported token fee provider")
            return
        }

        selectedProviderSubject.send(supportedFeeProvider)
    }
}

// MARK: - CustomStringConvertible

extension CommonTokenFeeProvidersManager: CustomStringConvertible {
    var description: String {
        objectDescription(self, userInfo: [
            "providers": feeProviders.count,
            "selectedProvider": selectedProviderSubject.value.feeTokenItem.name,
        ])
    }
}
