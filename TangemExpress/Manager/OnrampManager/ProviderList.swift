//
//  ProviderList.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public typealias ProvidersList = [ProviderItem]

// MARK: - Array<ProviderItem>

public extension ProvidersList {
    func hasProviders() -> Bool {
        !flatMap { $0.providers }.isEmpty
    }

    func successfullyLoadedProviders() -> [OnrampProvider] {
        flatMap { $0.providers }.filter { $0.isSuccessfullyLoaded }
    }

    func select(for paymentMethod: OnrampPaymentMethod.MethodType) -> ProviderItem? {
        first(where: { $0.paymentMethod.type == paymentMethod })
    }

    func sorted(sorter: ProviderItemSorter) -> Self {
        forEach { $0.sort() }

        return sorted { lhs, rhs in
            // If paymentMethod has same priority (e.g. SEPA and Revolut Pay)
            guard lhs.paymentMethod.type.priority == rhs.paymentMethod.type.priority else {
                return lhs.paymentMethod.type.priority > rhs.paymentMethod.type.priority
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

    /// Providers will be sorted and their `attractiveType` will be updated
    func updateAttractiveTypes() {
        let providers = flatMap { $0.providers }

        // Only if we have more than one providers with quote
        guard providers.filter(\.isSuccessfullyLoaded).count > 1 else {
            providers.forEach { $0.update(attractiveType: .none) }
            return
        }

        let bestQuote: Decimal? = providers.compactMap { $0.quote?.expectedAmount }.max()

        forEach {
            $0.sort().forEach { provider in
                switch provider.state {
                case .loaded(let quote) where quote.expectedAmount == bestQuote:
                    provider.update(globalAttractiveType: .best)

                case .loaded(let quote) where bestQuote != nil:
                    let percent = quote.expectedAmount / bestQuote! - 1
                    provider.update(globalAttractiveType: .loss(percent: percent))

                default:
                    provider.update(globalAttractiveType: .none)
                }
            }
        }
    }

    func updateProcessingTimeTypes() {
        let providers = flatMap { $0.providers }
        let fastest = providers.sorted(by: \.paymentMethod.type.processingTime).first

        providers.forEach { provider in
            switch provider {
            case let provider where provider == fastest:
                provider.update(processingTimeType: .fastest)
            case let provider:
                provider.update(processingTimeType: .none)
            }
        }
    }

    func globalBest() -> OnrampProvider? {
        flatMap { $0.providers }.first(where: { $0.globalAttractiveType == .best })
    }

    func fastest() -> OnrampProvider? {
        flatMap { $0.providers }.first(where: { $0.processingTimeType == .fastest })
    }
}
