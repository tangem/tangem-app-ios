//
//  CommonOnrampManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemFoundation

public actor CommonOnrampManager {
    private let apiProvider: ExpressAPIProvider
    private let onrampRepository: OnrampRepository
    private let dataRepository: OnrampDataRepository
    private let analyticsLogger: ExpressAnalyticsLogger
    private let sorter: ProviderItemSorter
    private let preferredValues: PreferredValues

    public init(
        apiProvider: ExpressAPIProvider,
        onrampRepository: OnrampRepository,
        dataRepository: OnrampDataRepository,
        analyticsLogger: ExpressAnalyticsLogger,
        sorter: ProviderItemSorter,
        preferredValues: PreferredValues
    ) {
        self.apiProvider = apiProvider
        self.onrampRepository = onrampRepository
        self.dataRepository = dataRepository
        self.analyticsLogger = analyticsLogger
        self.sorter = sorter
        self.preferredValues = preferredValues
    }
}

// MARK: - OnrampManager

extension CommonOnrampManager: OnrampManager {
    public func initialSetupCountry() async throws -> OnrampCountry {
        let country = try await apiProvider.onrampCountryByIP()
        return country
    }

    public func setupProviders(request item: OnrampPairRequestItem) async throws -> ProvidersList {
        let pairs = try await apiProvider.onrampPairs(
            from: item.fiatCurrency,
            to: [item.destination],
            country: item.country
        )

        let supportedProviders = pairs.flatMap { $0.providers }
        OnrampLogger.info(self, "Load pairs with supported providers \(supportedProviders)")
        guard !supportedProviders.isEmpty else {
            // Exclude unnecessary requests
            return []
        }

        // Return the `providers` with all possible options
        let providers = try await prepareProviders(item: item, supportedProviders: supportedProviders)
        return providers
    }

    public func setupQuotes(in providers: ProvidersList, amount: OnrampUpdatingAmount) async throws -> (list: ProvidersList, provider: OnrampProvider) {
        OnrampLogger.info(self, "Start update quotes for amount: \(amount)")
        try await updateQuotesInEachManager(providers: providers, amount: amount)
        OnrampLogger.info(self, "The quotes was updated for amount: \(amount)")

        providers.sortNestedProviders()
        providers.updateSupportedPaymentMethods()
        providers.updateAttractiveTypes()
        providers.updateProcessingTimeTypes(preferredProviderId: preferredValues.providerId)

        // `suggestProvider` logic will be remove
        // [REDACTED_TODO_COMMENT]
        let sorted = providers.sortedByFirstItem(sorter: sorter)
        let suggestProvider = try suggestProvider(in: sorted)

        return (list: sorted, provider: suggestProvider)
    }

    public func loadRedirectData(provider: OnrampProvider, redirectSettings: OnrampRedirectSettings) async throws -> OnrampRedirectData {
        do {
            let item = try provider.makeOnrampQuotesRequestItem()
            let requestItem = OnrampRedirectDataRequestItem(quotesItem: item, redirectSettings: redirectSettings)
            let data = try await apiProvider.onrampData(item: requestItem)
            return data
        } catch let error as ExpressAPIError {
            analyticsLogger.logExpressAPIError(error, provider: provider.provider, paymentMethod: provider.paymentMethod)
            throw error
        } catch {
            analyticsLogger.logAppError(error, provider: provider.provider)
            throw error
        }
    }
}

// MARK: - Private

private extension CommonOnrampManager {
    func updateQuotesInEachManager(providers: ProvidersList, amount: OnrampUpdatingAmount) async throws {
        if providers.isEmpty {
            throw OnrampManagerError.providersIsEmpty
        }

        await withTaskGroup(of: Void.self) { group in
            providers.flatMap { $0.providers }.forEach { provider in
                _ = group.addTaskUnlessCancelled {
                    await provider.update(amount: amount)
                }
            }
        }
    }

    func suggestProvider(in providers: ProvidersList) throws -> OnrampProvider {
        OnrampLogger.info(self, "Start to find the best provider")

        if let paymentMethodType = preferredValues.paymentMethodType {
            OnrampLogger.info(self, "Has preferredValues \(preferredValues)")

            if let providerItem = providers.select(for: paymentMethodType) {
                if let providerId = preferredValues.providerId,
                   let maxPriorityProvider = providerItem.preferredProvider(providerId: providerId) {
                    OnrampLogger.info(self, "The selected preferred provider is \(preferredValues)")
                    return maxPriorityProvider
                }

                if let maxPriorityProvider = providerItem.maxPriorityProvider() {
                    OnrampLogger.info(self, "The selected max priority provider for preferred paymentMethodType is \(maxPriorityProvider)")
                    return maxPriorityProvider
                }
            }
        }

        for provider in providers {
            OnrampLogger.info(self, "Providers for paymentMethod: \(provider.paymentMethod.name) was sorted to order: \(provider.providers)")

            if let maxPriorityProvider = provider.maxPriorityProvider() {
                OnrampLogger.info(self, "The selected max priority provider is \(maxPriorityProvider)")
                return maxPriorityProvider
            }
        }

        OnrampLogger.info(self, "We couldn't find any provider without error")
        OnrampLogger.info(self, "Start the second search to find any provider to show user")

        for provider in providers {
            if let suggestProvider = provider.selectableProvider() {
                OnrampLogger.info(self, "Then update selected provider to \(suggestProvider as Any)")
                return suggestProvider
            }
        }

        OnrampLogger.info(self, "We couldn't find any provider to suggest")
        throw OnrampManagerError.suggestedProviderNotFound
    }

    func prepareProviders(item: OnrampPairRequestItem, supportedProviders: [OnrampPair.Provider]) async throws -> ProvidersList {
        // Start two async requests
        async let providersList = dataRepository.providers()
        async let paymentMethodsList = dataRepository.paymentMethods()

        let providers = try await providersList.toSet()
        let paymentMethods = try await paymentMethodsList.toSet()

        let fullfilled: [ExpressProvider: [OnrampPaymentMethod]] = supportedProviders.reduce(into: [:]) { result, supportedProvider in
            if let provider = providers.first(where: { $0.id == supportedProvider.id }) {
                let paymentMethods = supportedProvider.paymentMethods.compactMap { paymentMethodId in
                    paymentMethods.first(where: { $0.id == paymentMethodId })
                }
                result[provider] = paymentMethods
            }
        }

        let supportedPaymentMethods = fullfilled.values.flatMap { $0 }.unique()

        let availableProviders: ProvidersList = supportedPaymentMethods.map { paymentMethod in
            let providers = providers.map { provider in
                OnrampProvider(
                    provider: provider,
                    paymentMethod: paymentMethod,
                    manager: makeOnrampProviderManager(
                        item: item,
                        provider: provider,
                        paymentMethod: paymentMethod,
                        supportedProviders: supportedProviders,
                        supportedPaymentMethods: fullfilled[provider] ?? []
                    )
                )
            }
            return ProviderItem(paymentMethod: paymentMethod, providers: providers)
        }

        OnrampLogger.info(self, "Built providers \(availableProviders)")

        return availableProviders
    }

    func makeOnrampProviderManager(
        item: OnrampPairRequestItem,
        provider: ExpressProvider,
        paymentMethod: OnrampPaymentMethod,
        supportedProviders: [OnrampPair.Provider],
        supportedPaymentMethods: [OnrampPaymentMethod]
    ) -> OnrampProviderManager {
        let state: OnrampProviderManagerState = {
            guard let supportedProvider = supportedProviders.first(where: { $0.id == provider.id }) else {
                return .notSupported(.currentPair)
            }

            let isSupportedForPaymentMethods = supportedProvider.paymentMethods.contains { $0 == paymentMethod.id }
            guard isSupportedForPaymentMethods else {
                return .notSupported(.paymentMethod(supportedMethods: supportedPaymentMethods))
            }

            return .idle
        }()

        return CommonOnrampProviderManager(
            pairItem: item,
            expressProvider: provider,
            paymentMethod: paymentMethod,
            apiProvider: apiProvider,
            analyticsLogger: analyticsLogger,
            state: state
        )
    }
}

extension CommonOnrampManager: @preconcurrency CustomStringConvertible {
    public var description: String { objectDescription(self) }
}
