//
//  CommonTokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class CommonTokenFeeProvidersManager {
    private let feeProviders: [any TokenFeeProvider]

    private let selectedProviderSubject: CurrentValueSubject<any TokenFeeProvider, Never>

    init(
        feeProviders: [any TokenFeeProvider],
        initialSelectedProvider: any TokenFeeProvider
    ) {
        self.feeProviders = feeProviders
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
    }

    func updateSelectedFeeProvider(feeTokenItem: TokenItem) {
        guard let tokenFeeProvider = feeProviders.first(where: { $0.feeTokenItem == feeTokenItem }) else {
            FeeLogger.warning(self, "Provider for token item \(feeTokenItem.name) not found")
            return
        }

        guard tokenFeeProvider.state.isSupported else {
            FeeLogger.info(self, "Provider for token item \(feeTokenItem.name) is not supported. Will not select")
            return
        }

        selectedProviderSubject.send(tokenFeeProvider)
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
