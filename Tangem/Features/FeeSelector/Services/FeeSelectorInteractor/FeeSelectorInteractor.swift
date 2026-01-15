//
//  FeeSelectorInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

protocol FeeSelectorInteractorInput: AnyObject {
    var selectedFee: LoadableTokenFee { get }
    var selectedFeePublisher: AnyPublisher<LoadableTokenFee, Never> { get }
}

protocol FeeSelectorInteractor: FeeSelectorTokensDataProvider, FeeSelectorFeesDataProvider, FeeSelectorCustomFeeDataProviding {
    func userDidSelect(tokenFeeProvider: any TokenFeeProvider)
    func userDidSelectFee(_ fee: LoadableTokenFee)
}

extension FeeSelectorInteractor {
    var hasMultipleFeeProviders: Bool { selectorTokenFeeProviders.count > 1 }
    var hasMultipleFeeProvidersPublisher: AnyPublisher<Bool, Never> {
        selectorTokenFeeProvidersPublisher.map { $0.count > 1 }.eraseToAnyPublisher()
    }

    var selectorHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(
            selectorFeesPublisher.map { $0.hasMultipleFeeOptions },
            hasMultipleFeeProvidersPublisher,
        )
        .map { $0 || $1 }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
