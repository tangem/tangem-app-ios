//
//  ProviderItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public typealias ProvidersList = [ProviderItem]

public class ProviderItem {
    public let paymentMethod: OnrampPaymentMethod
    public let sorter: ProviderItemSorter

    public private(set) var providers: [OnrampProvider]

    init(
        paymentMethod: OnrampPaymentMethod,
        sorter: ProviderItemSorter,
        providers: [OnrampProvider]
    ) {
        self.paymentMethod = paymentMethod
        self.sorter = sorter
        self.providers = providers
    }

    public func hasSelectableProviders() -> Bool {
        providers.contains { $0.isShowable && $0.isSelectable }
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
        providers.sort(by: { sorter.sort(lhs: $0, rhs: $1) })
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

// MARK: - Array<ProviderItem>

public extension ProvidersList {
    func hasProviders() -> Bool {
        !flatMap { $0.providers }.isEmpty
    }

    func select(for paymentMethod: OnrampPaymentMethod) -> ProviderItem? {
        first(where: { $0.paymentMethod == paymentMethod })
    }

    func sorted(sorter: some ProviderItemSorter) -> Self {
        forEach { $0.sort() }

        return sorted { lhs, rhs in
            // If paymentMethod has same priority (e.g. SEPA and Revolut Pay)
            guard lhs.paymentMethod.type == rhs.paymentMethod.type else {
                return sorter.sort(lhs: lhs.paymentMethod, rhs: rhs.paymentMethod)
            }

            switch (lhs.providers.first, rhs.providers.first) {
            case (.some(let lhsProvider), .some(let rhsProvider)):
                return sorter.sort(lhs: lhsProvider, rhs: rhsProvider)
            case (.none, _), (_, .none):
                return false
            }
        }
    }

    func updateSupportedPaymentMethods() {
        flatMap { $0.providers }.forEach { provider in
            guard case .notSupported(.paymentMethod) = provider.state else {
                return
            }

            let supportedMethods = flatMap { $0.providers }
                .filter { $0.provider == provider.provider && $0.isLoaded }
                .map(\.paymentMethod)

            provider.update(supportedMethods: supportedMethods)
        }
    }
}
