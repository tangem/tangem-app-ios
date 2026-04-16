//
//  CommonExpressManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLogger
import TangemFoundation

actor CommonExpressManager {
    // MARK: - Dependencies

    private let expressAPIProvider: ExpressAPIProvider
    private let expressProviderManagerFactory: ExpressProviderManagerFactory
    private let expressRepository: ExpressRepository

    // MARK: - State

    private var _pair: ExpressManagerSwappingPair?
    private var _amountType: ExpressAmountType?

    private var availableProviders: [ExpressAvailableProvider] = []
    private var selectedProvider: ExpressAvailableProvider?

    init(
        expressAPIProvider: ExpressAPIProvider,
        expressProviderManagerFactory: ExpressProviderManagerFactory,
        expressRepository: ExpressRepository
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.expressProviderManagerFactory = expressProviderManagerFactory
        self.expressRepository = expressRepository
    }
}

// MARK: - ExpressManager

extension CommonExpressManager: ExpressManager {
    func getPair() -> ExpressManagerSwappingPair? {
        return _pair
    }

    func getAmountType() -> ExpressAmountType? {
        return _amountType
    }

    func getRateType() -> ExpressProviderRateType? {
        guard let amountType = _amountType, let selected = selectedProvider else { return nil }

        if selected.supportedRateTypes.contains(amountType.rateType) {
            return amountType.rateType
        }

        return selected.supportedRateTypes.first
    }

    func getSelectedProvider() -> ExpressAvailableProvider? {
        return selectedProvider
    }

    func getAllProviders() -> [ExpressAvailableProvider] {
        return availableProviders
    }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressAvailableProvider? {
        pair.map { assert($0.source.currency != $0.destination.currency, "Pair has equal currencies") }
        _pair = pair

        // Clear for reselected the best quote
        clearCache()

        switch pair {
        case .some(let pair): try await updateAvailableProviders(pair: pair)
        case .none: availableProviders.removeAll()
        }

        return await bestProvider()
    }

    func update(amountType: ExpressAmountType?, by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider? {
        _amountType = amountType
        return try await update(by: source)
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressAvailableProvider? {
        selectedProvider = provider

        return selectedProvider
    }

    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider? {
        try await updateState(by: source)
    }

    func requestData() async throws -> ExpressTransactionData {
        guard let selectedProvider = selectedProvider else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let request = try makeRequest(for: selectedProvider)
        return try await selectedProvider.manager.sendData(request: request)
    }
}

// MARK: - Private

private extension CommonExpressManager {
    /// Return the state which checking the all properties
    func updateState(by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider? {
        guard let pair = _pair else {
            ExpressLogger.warning("Pair isn't set. Return nil as `selectedProvider`")
            return nil
        }

        try Task.checkCancellation()

        guard let amountType = _amountType, amountType.amount > 0 else {
            ExpressLogger.warning(self, "Amount isn't set. Return nil as `selectedProvider`")
            return nil
        }

        let request = try makeRequest()
        await updateStatesInProviders(request: request)

        try Task.checkCancellation()

        await updateSelectedProvider(pair: pair, by: source)

        return try selectedProviderState()
    }

    func selectedProviderState() throws -> ExpressAvailableProvider? {
        let state = selectedProvider?.getState()
        ExpressLogger.info(self, "Selected provider state: \(state as Any)")

        return selectedProvider
    }

    func updateAvailableProviders(pair: ExpressManagerSwappingPair) async throws {
        async let allIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: nil)
        async let fixedIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .fixed)
        async let floatIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .float)
        let (allSet, fixedSet, floatSet) = await (Set(allIds), Set(fixedIds), Set(floatIds))

        let providers = try await expressRepository.providers()

        availableProviders = try providers.compactMap { provider in
            guard allSet.contains(provider.id),
                  pair.source.supportedProvidersFilter.isSupported(provider: provider) else {
                return nil
            }

            guard let manager = expressProviderManagerFactory.makeExpressProviderManager(provider: provider, pair: pair) else {
                throw ExpressManagerError.unsupportedProviderType
            }

            var rateTypes: Set<ExpressProviderRateType> = []
            if floatSet.contains(provider.id) { rateTypes.insert(.float) }
            if fixedSet.contains(provider.id) { rateTypes.insert(.fixed) }

            return ExpressAvailableProvider(provider: provider, manager: manager, supportedRateTypes: rateTypes, isBest: false)
        }
    }

    func updateSelectedProvider(pair: ExpressManagerSwappingPair, by source: ExpressProviderUpdateSource) async {
        if source.isRequiredUpdateSelectedProvider || selectedProvider == nil {
            selectedProvider = await bestProvider()

            if let selectedProvider {
                pair.source.analyticsLogger.bestProviderSelected(selectedProvider)
            }
        }
    }

    var candidateProviders: [ExpressAvailableProvider] {
        let filtered = availableProviders.filteredByRateType(_amountType?.rateType)
        return filtered.isEmpty ? availableProviders : filtered
    }

    func updateIsBestFlag() {
        let candidates = candidateProviders
        let bestRate = bestByRateProvider(from: candidates)

        let enabledProvidersMoreThanOne = eligibleProviders(from: candidates).count > 1

        availableProviders.forEach { provider in
            // We set the `isBest` flag only if we have more than one enabled provider
            let isBest = enabledProvidersMoreThanOne && provider.provider == bestRate?.provider
            provider.update(isBest: isBest)

            ExpressLogger.info(self, "Update provider \(provider.provider.name) isBest? - \(provider.isBest)")
        }
    }

    func bestProvider() async -> ExpressAvailableProvider? {
        let candidates = candidateProviders

        // If we have more than one provider then select the best
        if candidates.count > 1 {
            // Try to find the best with expectAmount
            if let bestByRateProvider = bestByRateProvider(from: candidates) {
                return bestByRateProvider
            }
        }

        // If all candidates don't have the quote and the expectAmount
        // Just select the provider by priority
        return candidates.sorted(by: { $0.getPriority() > $1.getPriority() }).first
    }

    func bestByRateProvider(from candidates: [ExpressAvailableProvider]? = nil) -> ExpressAvailableProvider? {
        let providers = candidates ?? candidateProviders
        let isFixedRate = _amountType?.rateType == .fixed

        let eligible = eligibleProviders(from: providers)

        guard !eligible.isEmpty else {
            return nil
        }

        return eligible.sorted(by: { lhsProvider, rhsProvider in
            let lhsQuote = lhsProvider.getState().quote
            let rhsQuote = rhsProvider.getState().quote

            if isFixedRate {
                // Fixed mode: lowest fromAmount is best (cheapest cost for user)
                guard let lhs = lhsQuote?.fromAmount, let rhs = rhsQuote?.fromAmount else { return false }
                return lhs < rhs
            } else {
                // Float mode: highest expectAmount is best (most received)
                guard let lhs = lhsQuote?.expectAmount, let rhs = rhsQuote?.expectAmount else { return false }
                return lhs > rhs
            }
        }).first
    }

    func eligibleProviders(from providers: [ExpressAvailableProvider]) -> [ExpressAvailableProvider] {
        providers.filter { provider in
            let state = provider.getState()
            switch state {
            case .error, .restriction(.tooSmallAmount, _), .restriction(.tooBigAmount, _):
                return false
            default:
                return state.quote != nil
            }
        }
    }

    func updateStatesInProviders(request: ExpressManagerSwappingPairRequest) async {
        let candidates = candidateProviders

        let providers = candidates.map { $0.provider.name }.joined(separator: ", ")
        ExpressLogger.info(self, "Start a parallel updating in providers: \(providers) with request \(request)")

        // Run a parallel asynchronous tasks
        await withTaskGroup(of: Void.self) { taskGroup in
            candidates.forEach { provider in
                let providerRequest = request.with(rateType: resolveRateType(for: provider))
                taskGroup.addTask {
                    await provider.manager.update(request: providerRequest)
                }
            }
        }

        // Update "isBest" flag after each provider's state updating
        updateIsBestFlag()
    }

    func makeRequest(for provider: ExpressAvailableProvider? = nil) throws -> ExpressManagerSwappingPairRequest {
        guard let pair = _pair else {
            throw ExpressManagerError.pairNotFound
        }

        guard let amountType = _amountType, amountType.amount > 0 else {
            throw ExpressManagerError.amountNotFound
        }

        let rateType: ExpressProviderRateType
        if let provider {
            rateType = resolveRateType(for: provider)
        } else {
            rateType = amountType.rateType
        }

        return ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            operationType: pair.source.operationType
        )
    }

    func resolveRateType(for provider: ExpressAvailableProvider) -> ExpressProviderRateType {
        if let preferred = _amountType?.rateType, provider.supportedRateTypes.contains(preferred) {
            return preferred
        }
        return provider.supportedRateTypes.first ?? .float
    }

    func clearCache() {
        selectedProvider = nil
    }
}

// MARK: - CustomStringConvertible

extension CommonExpressManager: @preconcurrency CustomStringConvertible {
    var description: String { objectDescription(self) }
}

// MARK: - SupportedProvidersFilter+

private extension SupportedProvidersFilter {
    func isSupported(provider: ExpressProvider) -> Bool {
        switch self {
        case .byTypes(let types):
            return types.contains(provider.type)
        case .byDifferentAddressExchangeSupport:
            return !provider.exchangeOnlyWithinSingleAddress
        }
    }
}
