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
import BlockchainSdk

actor CommonExpressManager {
    // MARK: - Dependencies

    private let expressAPIProvider: ExpressAPIProvider
    private let expressProviderManagerFactory: ExpressProviderManagerFactory
    private let expressRepository: ExpressRepository

    // MARK: - State

    private var _pair: ExpressManagerSwappingPair?
    private var _approvePolicy: ApprovePolicy = .specified
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

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult {
        pair.map { assert($0.source.currency != $0.destination.currency, "Pair has equal currencies") }
        _pair = pair

        // Clear for reselected the best quote
        clearCache()

        switch pair {
        case .some(let pair): try await updateAvailableProviders(pair: pair)
        case .none: availableProviders.removeAll()
        }

        let selected = await bestProvider()
        return makeUpdatingResult(selected: selected)
    }

    func update(amountType: ExpressAmountType?) async -> ExpressManagerUpdatingResult {
        _amountType = amountType
        return await update(type: .amount)
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerUpdatingResult {
        selectedProvider = provider

        return makeUpdatingResult(selected: selectedProvider)
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerUpdatingResult {
        guard _approvePolicy != approvePolicy else {
            ExpressLogger.warning(self, "ApprovePolicy already is \(approvePolicy)")
            return makeUpdatingResult(selected: selectedProvider)
        }

        _approvePolicy = approvePolicy

        let request = try makeRequest(for: selectedProvider)
        await selectedProvider?.updateState(request: request)
        return makeUpdatingResult(selected: selectedProvider)
    }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerUpdatingResult {
        let selected: ExpressAvailableProvider?
        do {
            selected = try await updateState(by: type)
        } catch {
            ExpressLogger.warning(self, "update(type: \(type)) failed: \(error)")
            selected = selectedProvider
        }
        return makeUpdatingResult(selected: selected)
    }

    func requestData() async throws -> ExpressTransactionData {
        guard let selectedProvider = selectedProvider else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let request = try makeRequest(for: selectedProvider)
        return try await selectedProvider.requestData(request: request)
    }
}

// MARK: - Private

private extension CommonExpressManager {
    /// Return the state which checking the all properties
    func updateState(by source: ExpressManagerUpdatingType) async throws -> ExpressAvailableProvider? {
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

            var rateTypes: Set<ExpressProviderRateType> = []
            if floatSet.contains(provider.id) { rateTypes.insert(.float) }
            if fixedSet.contains(provider.id) { rateTypes.insert(.fixed) }

            return try expressProviderManagerFactory.makeExpressProviderManager(
                provider: provider,
                pair: pair,
                supportedRateTypes: rateTypes
            )
        }
    }

    func updateSelectedProvider(pair: ExpressManagerSwappingPair, by source: ExpressManagerUpdatingType) async {
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
        let rateType = _amountType?.rateType ?? .float
        availableProviders.updateIsBestFlag(rateType: rateType)

        let summary = availableProviders.map { "\($0.provider.name)=\($0.isBest)" }.joined(separator: ", ")
        ExpressLogger.info(self, "isBest flags: \(summary)")
    }

    func bestProvider() async -> ExpressAvailableProvider? {
        let rateType = _amountType?.rateType ?? .float
        return candidateProviders.best(rateType: rateType)
    }

    func updateStatesInProviders(request: ExpressManagerSwappingPairRequest) async {
        let candidates = candidateProviders

        defer { updateIsBestFlag() }

        let providers = candidates.map { $0.provider.name }.joined(separator: ", ")
        ExpressLogger.info(self, "Start a parallel updating in providers: \(providers) with request \(request)")

        guard candidates.isNotEmpty else {
            return
        }

        let tracker = ExpressQuotesLoadingPerformanceTracker.started(providersCount: candidates.count)
        let request = request.with(quotesLoadingPerformanceTracker: tracker)

        // Run a parallel asynchronous tasks
        await withTaskGroup(of: Void.self) { taskGroup in
            candidates.forEach { provider in
                let providerRequest = request.with(rateType: resolveRateType(for: provider))
                taskGroup.addTask {
                    await provider.updateState(request: providerRequest)
                }
            }
        }
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
            approvePolicy: _approvePolicy,
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

    func makeUpdatingResult(selected: ExpressAvailableProvider?) -> ExpressManagerUpdatingResult {
        let result = ExpressManagerUpdatingResult(providers: availableProviders, selected: selected)
        ExpressLogger.info(self, "Updating result: \(result.description)")
        return result
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
