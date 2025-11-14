//
//  ProviderItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public class ProviderItem: Identifiable {
    public var id: String { paymentMethod.id }

    public let paymentMethod: OnrampPaymentMethod
    public private(set) var providers: [OnrampProvider]

    init(
        paymentMethod: OnrampPaymentMethod,
        providers: [OnrampProvider]
    ) {
        self.paymentMethod = paymentMethod
        self.providers = providers
    }

    public func hasSuccessfullyLoadedProviders() -> Bool {
        !successfullyLoadedProviders().isEmpty
    }

    public func successfullyLoadedProviders() -> [OnrampProvider] {
        providers.filter { $0.isSuccessfullyLoaded }
    }

    public func hasSelectableProviders() -> Bool {
        !selectableProviders().isEmpty
    }

    public func selectableProviders() -> [OnrampProvider] {
        providers.filter { $0.isShowable && $0.isSelectable }
    }

    /// Provider which can be showed and selected
    public func maxPriorityProvider() -> OnrampProvider? {
        providers.first(where: { $0.isShowable && $0.isSelectable })
    }

    /// Provider which can be showed and selected
    public func preferredProvider(providerId: String) -> OnrampProvider? {
        providers.first(where: { $0.provider.id == providerId && $0.isShowable && $0.isSelectable })
    }

    /// Provider which can be selected by user
    public func selectableProvider() -> OnrampProvider? {
        providers.first(where: { $0.isSelectable })
    }

    @discardableResult
    public func sort() -> [OnrampProvider] {
        providers.sort(by: >)
        // Return sorted providers
        return providers
    }

    /// Providers will be sorted and their `attractiveType` will be updated
    public func updateAttractiveTypes() {
        // Only if we have more than one providers with quote
        guard providers.filter(\.isSuccessfullyLoaded).count > 1 else {
            providers.forEach { $0.update(attractiveType: .none) }
            return
        }

        var bestQuote: Decimal?

        sort().indexed().forEach { index, provider in
            switch (index, provider.state) {
            case (.zero, .loaded(let quote)):
                provider.update(attractiveType: .best)
                bestQuote = quote.expectedAmount

            case (_, .loaded(let quote)) where bestQuote != nil:
                let percent = quote.expectedAmount / bestQuote! - 1
                provider.update(attractiveType: .loss(percent: percent))

            case (_, _):
                provider.update(attractiveType: .none)
            }
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension ProviderItem: CustomDebugStringConvertible {
    public var debugDescription: String {
        objectDescription(self, userInfo: [
            "paymentMethod": paymentMethod.name,
            "providers": providers.map {
                "providerName: \($0.provider.name), state: \($0.state)"
            },
        ])
    }
}
