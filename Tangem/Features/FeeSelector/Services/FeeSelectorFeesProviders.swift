//
//  FeeSelectorFeesProviders.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeeSelectorFeeTokenItemsProvider {
    var tokenItems: [TokenItem] { get }
    var tokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }
}

protocol FeeSelectorFeesProvider {
    var fees: [SendFee] { get }
    var feesPublisher: AnyPublisher<[SendFee], Never> { get }
}

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
    func subscribeToInitialSetup(feeProvider: any FeeSelectorInteractor) -> AnyCancellable {
        feeProvider.feesPublisher
            .compactMap { $0.first(where: { $0.option == .market })?.value.value }
            .first()
            .sink { initialSetupCustomFee($0) }
    }
}
