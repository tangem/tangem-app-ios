//
//  FeeSelectorFeesProviders.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

// MARK: - Main fees

typealias FeeSelectorFeesProvider = TokenFeeProvider
// protocol FeeSelectorFeesProvider {
//    var fees: [TokenFee] { get }
//    var feesPublisher: AnyPublisher<[TokenFee], Never> { get }
// }

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
    var suggestedFee: TokenFee { get }
    var suggestedFeePublisher: AnyPublisher<TokenFee, Never> { get }
}

typealias CustomFeeProvider = FeeSelectorCustomFeeProvider & FeeSelectorCustomFeeAvailabilityProvider & FeeSelectorCustomFeeFieldsBuilder

protocol FeeSelectorCustomFeeProvider {
    var customFee: TokenFee { get }
    var customFeePublisher: AnyPublisher<TokenFee, Never> { get }

    func initialSetupCustomFee(_ fee: BSDKFee)
}

extension FeeSelectorCustomFeeProvider {
    func subscribeToInitialSetup(feeProviders: any FeeSelectorFeesProvider) -> AnyCancellable {
        feeProviders.feesPublisher
            .print("->> feesPublisher")
            .compactMap { $0.first(where: { $0.option == .market })?.value.value }
            .first()
            .sink { initialSetupCustomFee($0) }
    }
}
