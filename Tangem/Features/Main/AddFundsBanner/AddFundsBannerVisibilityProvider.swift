//
//  AddFundsBannerVisibilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol AddFundsBannerVisibilityProvider: AnyObject {
    /// Emits the Add Funds banner decision for the given wallet: `true` once its balance resolves
    /// to zero, `false` once it resolves to a positive value. Emits nothing while the balance is
    /// unresolved, so the decision stays pending on the consumer side.
    func shouldShowPublisher(for totalBalanceProvider: TotalBalanceProvider) -> AnyPublisher<Bool, Never>
}

final class CommonAddFundsBannerVisibilityProvider {
    fileprivate init() {}
}

// MARK: - AddFundsBannerVisibilityProvider

extension CommonAddFundsBannerVisibilityProvider: AddFundsBannerVisibilityProvider {
    func shouldShowPublisher(for totalBalanceProvider: TotalBalanceProvider) -> AnyPublisher<Bool, Never> {
        return totalBalanceProvider.totalBalancePublisher
            .compactMap { state -> Bool? in
                switch state {
                case .loaded, .loading(.some), .failed(.some, _):
                    return !state.hasAnyPositiveBalance
                case .empty, .loading(.none), .failed(.none, _):
                    // Balance not resolved yet — keep the Add Funds decision pending
                    return nil
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Injection

private struct AddFundsBannerVisibilityProviderKey: InjectionKey {
    static var currentValue: AddFundsBannerVisibilityProvider = CommonAddFundsBannerVisibilityProvider()
}

extension InjectedValues {
    var addFundsBannerVisibilityProvider: AddFundsBannerVisibilityProvider {
        get { Self[AddFundsBannerVisibilityProviderKey.self] }
        set { Self[AddFundsBannerVisibilityProviderKey.self] = newValue }
    }
}
