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

    func sortNestedProviders() {
        forEach { $0.sort() }
    }

    func sortedByFirstItem(sorter: ProviderItemSorter) -> Self {
        sorted { lhs, rhs in
            sorter.sort(lhs: lhs, rhs: rhs)
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
            providers.forEach { $0.update(globalAttractiveType: .none) }
            return
        }

        let greatProvider = select(for: .sepa)?.maxPriorityProvider()
        let bestProvider: OnrampProvider? = providers.min()
        let bestQuote: Decimal? = bestProvider?.quote?.expectedAmount

        providers.forEach { provider in
            switch provider.state {
            case .loaded where provider == bestProvider:
                provider.update(globalAttractiveType: .best)

            case .loaded(let quote) where provider == greatProvider && provider != bestProvider:
                let percent = bestQuote.map { quote.expectedAmount / $0 - 1 }
                provider.update(globalAttractiveType: .great(percent: percent))

            case .loaded(let quote) where bestQuote != nil:
                let percent = quote.expectedAmount / bestQuote! - 1
                let rounded = percent.rounded(scale: 4)
                provider.update(globalAttractiveType: .loss(percent: rounded))

            default:
                provider.update(globalAttractiveType: .none)
            }
        }
    }

    func updateProcessingTimeTypes(preferredProviderId: String?) {
        let providers = flatMap { $0.providers }

        // Setup fastest badge only if there is more than one successfully loaded provider
        guard providers.filter(\.isSuccessfullyLoaded).count > 1 else {
            providers.forEach { $0.update(processingTimeType: .none) }
            return
        }

        let fastestProviderItem = min(by: \.paymentMethod.type.processingTime)
        let successfullyLoadedProviders = fastestProviderItem?.providers.filter(\.isSuccessfullyLoaded)
        let preferredProvider = successfullyLoadedProviders?.first(where: { $0.provider.id == preferredProviderId })
        let fastestProvider = preferredProvider ?? successfullyLoadedProviders?.min()

        providers.forEach { provider in
            switch provider {
            case let provider where provider == fastestProvider:
                provider.update(processingTimeType: .fastest)
            case let provider:
                provider.update(processingTimeType: .none)
            }
        }
    }

    func great() -> OnrampProvider? {
        flatMap { $0.providers }.first(where: { $0.globalAttractiveType?.isGreat == true })
    }

    func best() -> OnrampProvider? {
        flatMap { $0.providers }.first(where: { $0.globalAttractiveType == .best })
    }

    func fastest() -> OnrampProvider? {
        flatMap { $0.providers }.first(where: { $0.processingTimeType == .fastest })
    }
}
