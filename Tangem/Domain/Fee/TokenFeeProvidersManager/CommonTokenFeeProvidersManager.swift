//
//  CommonTokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
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
                    .compactMap { bt -> Decimal? in
                        guard case .loaded(let value) = bt else { return nil }
                        return value
                    }

                return Publishers.CombineLatest(fee, balance)
                    .map { fee, balance in fee > balance } // Bool: не хватает?
                    .removeDuplicates() // важно!
                    .eraseToAnyPublisher()
            }
            .filter { $0 } // только когда стало true
            .sink { [weak self] _ in
                self?.updateToAnotherProviderWithBalance()
            }
    }

//    private func updateToAnotherProviderWithBalance() {
//        FeeLogger.info(self, "Detect that selected provider doesn't have enough balance to cover fee")
//        let supported = tokenFeeProviders.filter(\.state.isSupported).map(\.feeTokenItem)
//        let notUsedFeeTokenItem = supported.first(where: { !alreadyUsedProviders.contains($0) })
//
//        guard let notUsedFeeTokenItem else {
//            FeeLogger.info(self, "There are no other providers to choose from. Select the first one")
//            updateSelectedFeeProvider(feeTokenItem: initialSelectedProvider.feeTokenItem)
//            selectedFeeProvider.updateFees()
//
//            return
//        }
//
//        updateSelectedFeeProvider(feeTokenItem: notUsedFeeTokenItem)
//        selectedFeeProvider.updateFees()
//    }

    private func updateToAnotherProviderWithBalance() {
        let supported = tokenFeeProviders
            .filter(\.state.isSupported)
            .map(\.feeTokenItem)

        let notUsedFeeTokenItem = supported.first(where: { !alreadyUsedProviders.contains($0) })

        // ✅ если все уже перебрали — сбрасываем set и возвращаемся к initial
        guard let notUsedFeeTokenItem else {
            alreadyUsedProviders.removeAll()
            alreadyUsedProviders.insert(initialSelectedProvider.feeTokenItem)

            updateSelectedFeeProvider(feeTokenItem: initialSelectedProvider.feeTokenItem)
            selectedFeeProvider.updateFees()
            return
        }

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

    func updateFeeOptionInAllProviders(feeOption: FeeOption) {
        feeProviders.forEach { $0.select(feeOption: feeOption) }
    }

    func updateInputInAllProviders(input: TokenFeeProviderInputData) {
        feeProviders.forEach { $0.setup(input: input) }

        checkSelectedProviderIsSupported()
    }

    func updateSelectedFeeProvider(feeTokenItem: TokenItem) {
        guard let tokenFeeProvider = feeProviders.first(where: { $0.feeTokenItem == feeTokenItem }) else {
            return
        }

        guard tokenFeeProvider.state.isSupported else {
            return
        }

        // ✅ 1) не шлём повторно того же провайдера (ломает лупы)
        guard tokenFeeProvider.feeTokenItem != selectedFeeProvider.feeTokenItem else {
            return
        }

        // ✅ 2) помечаем как использованный
        alreadyUsedProviders.insert(tokenFeeProvider.feeTokenItem)

        // ✅ 3) переключаем
        selectedProviderSubject.send(tokenFeeProvider)
    }

//    func updateSelectedFeeProvider(feeTokenItem: TokenItem) {
//        guard let tokenFeeProvider = feeProviders.first(where: { $0.feeTokenItem == feeTokenItem }) else {
//            return
//        }
//
//        guard tokenFeeProvider.state.isSupported else {
//            FeeLogger.info(self, "Provider for token item \(feeTokenItem.name) is not supported. Will not select")
//            return
//        }
//
//        selectedProviderSubject.send(tokenFeeProvider)
//    }
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
