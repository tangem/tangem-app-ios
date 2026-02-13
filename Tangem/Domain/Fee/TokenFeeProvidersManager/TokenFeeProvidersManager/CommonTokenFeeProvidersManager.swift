//
//  CommonTokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress
import TangemFoundation

final class CommonTokenFeeProvidersManager {
    private let feeProviders: [any TokenFeeProvider]
    private let initialSelectedProvider: any TokenFeeProvider

    private let selectedProviderSubject: CurrentValueSubject<any TokenFeeProvider, Never>

    private var alreadyUsedProviders: Set<TokenItem> = []
    private var enoughFeeCheckingCancellable: AnyCancellable?

    init(
        feeProviders: [any TokenFeeProvider],
        initialSelectedProvider: any TokenFeeProvider
    ) {
        self.feeProviders = feeProviders
        self.initialSelectedProvider = initialSelectedProvider

        selectedProviderSubject = .init(initialSelectedProvider)
        alreadyUsedProviders = [initialSelectedProvider.feeTokenItem]

        bind()
    }

    private func bind() {
        enoughFeeCheckingCancellable = selectedProviderSubject
            .flatMapLatest { selectedProvider -> AnyPublisher<Bool, Never> in
                let fee = selectedProvider.selectedTokenFeePublisher
                    .compactMap { $0.value.value?.amount.value }

                let balance = selectedProvider.balanceTypePublisher
                    .compactMap { $0.loaded }

                return Publishers.CombineLatest(fee, balance)
                    .map { fee, balance in fee > balance }
                    .removeDuplicates()
                    .eraseToAnyPublisher()
            }
            .filter { $0 }
            .sink { [weak self] _ in
                self?.updateToAnotherProviderWithBalance()
            }
    }

    private func updateToAnotherProviderWithBalance() {
        FeeLogger.info(self, "Detect that selected provider doesn't have enough balance to cover fee")

        let supported = tokenFeeProviders
            .filter(\.state.isSupported)
            .map(\.feeTokenItem)

        let notUsedFeeTokenItem = supported.first(where: { !alreadyUsedProviders.contains($0) })

        guard let notUsedFeeTokenItem else {
            FeeLogger.info(self, "There are no other providers to choose from. Select the first one")

            alreadyUsedProviders.removeAll()
            alreadyUsedProviders.insert(initialSelectedProvider.feeTokenItem)

            updateSelectedFeeProvider(feeTokenItem: initialSelectedProvider.feeTokenItem)
            selectedFeeProvider.updateFees()
            return
        }

        alreadyUsedProviders.insert(notUsedFeeTokenItem)
        updateSelectedFeeProvider(feeTokenItem: notUsedFeeTokenItem)
        selectedFeeProvider.updateFees()
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
        feeProviders.hasMultipleFeeProviders || selectedFeeProvider.hasMultipleFeeOptions
    }

    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            selectedFeeProviderPublisher.map(\.hasMultipleFeeOptions),
            Just(feeProviders.hasMultipleFeeProviders)
        )
        .map { $0 || $1 }
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
            FeeLogger.warning(self, "Try to select already selected provider with token item \(feeTokenItem.name). Will not select")
            return
        }

        alreadyUsedProviders.insert(tokenFeeProvider.feeTokenItem)
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
        await selectedFeeProvider.updateFees().value

        let fee = try selectedFeeProvider.selectedTokenFee.value.get()
        return fee
    }

    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee {
        update(
            input: .dex(.ethereumEstimate(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee))
        )

        await selectedFeeProvider.updateFees().value
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

            await selectedFeeProvider.updateFees().value
            let fee = try selectedFeeProvider.selectedTokenFee.value.get()

            return fee

        case (.dex(let data), .solana):
            guard let txData = data.txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            update(input: .dex(.solana(compiledTransaction: transactionData)))
            await selectedFeeProvider.updateFees().value
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

            await selectedFeeProvider.updateFees().value
            let fee = try selectedFeeProvider.selectedTokenFee.value.get()

            return fee
        }
    }
}

// MARK: - Private

private extension CommonTokenFeeProvidersManager {
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
