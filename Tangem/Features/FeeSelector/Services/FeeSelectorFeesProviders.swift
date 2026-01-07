//
//  FeeSelectorFeesProviders.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

// MARK: - Main fees

protocol FeeSelectorFeesProvider {
    var fees: [SendFee] { get }
    var feesPublisher: AnyPublisher<[SendFee], Never> { get }
}

protocol FeeSelectorFeeTokenItemsProvider {
    var tokenItems: [TokenItem] { get }
    var tokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }

    func userDidSelectTokenItem(_ tokenItem: TokenItem)
}

extension FeeSelectorFeeTokenItemsProvider where Self: FeeSelectorFeesProvider {
    var tokenItems: [TokenItem] {
        fees.map(\.tokenItem).unique()
    }

    var tokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        feesPublisher.map { $0.map(\.tokenItem).unique() }.eraseToAnyPublisher()
    }
}

// MARK: - Custom fees

protocol FeeSelectorSuggestedFeeProvider {
    var suggestedFee: SendFee { get }
    var suggestedFeePublisher: AnyPublisher<SendFee, Never> { get }
}

protocol FeeSelectorCustomFeeProvider {
    var customFee: SendFee { get }
    var customFeePublisher: AnyPublisher<SendFee, Never> { get }

    func initialSetupCustomFee(_ fee: BSDKFee)
}

extension FeeSelectorCustomFeeProvider {
    func subscribeToInitialSetup(feeProviders: any FeeSelectorFeesProvider) -> AnyCancellable {
        feeProviders.feesPublisher
            .compactMap { $0.first(where: { $0.option == .market })?.value.value }
            .first()
            .sink { initialSetupCustomFee($0) }
    }
}
