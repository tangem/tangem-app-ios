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

    private var availableProviders: [ExpressAvailableProvider] = []
    private var selectedProvider: ExpressAvailableProvider?
    private var selectedAmountType: ExpressAmountType?
    private var selectedApprovePolicy: ApprovePolicy = .specified

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
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult {
        // Clear for reselected the best quote
        selectedProvider = nil

        switch pair {
        case .some(let pair):
            try await updateAvailableProviders(pair: pair)

        case .none:
            availableProviders.removeAll()
        }

        return currentResult()
    }

    func update(amountType: ExpressAmountType?) async -> ExpressManagerUpdatingResult {
        selectedAmountType = amountType

        // 1. Load quotes and update isBest flag for the active subset
        let providers = await reloadQuotesInProviders()

        // 2. Try to find best provider and select it
        selectedProvider = providers.best()
        logBestProviderSelected()

        return currentResult()
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerUpdatingResult {
        selectedProvider = provider
        return currentResult()
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerUpdatingResult {
        guard let selectedProvider else {
            return currentResult()
        }

        guard selectedApprovePolicy != approvePolicy else {
            ExpressLogger.warning(self, "ApprovePolicy already is \(approvePolicy)")
            return currentResult()
        }

        selectedApprovePolicy = approvePolicy
        let request = try makeRequest(amountType: selectedAmountType, provider: selectedProvider)
        await selectedProvider.updateState(request: request)

        return currentResult()
    }

    func autoupdate(source: ExpressProviderUpdateSource) async -> ExpressManagerUpdatingResult {
        let providers = await reloadQuotesInProviders()

        if source.isRequiredUpdateSelectedProvider {
            selectedProvider = providers.best()
            logBestProviderSelected()
        }

        return currentResult()
    }

    func requestData() async throws -> ExpressTransactionData {
        guard let selectedProvider = selectedProvider else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let request = try makeRequest(amountType: selectedAmountType, provider: selectedProvider)
        return try await selectedProvider.requestData(request: request)
    }
}

// MARK: - Private

private extension CommonExpressManager {
    func updateAvailableProviders(pair: ExpressManagerSwappingPair) async throws {
        async let allIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: nil)
        async let fixedIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .fixed)
        async let floatIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .float)
        let (allSet, fixedSet, floatSet) = await (Set(allIds), Set(fixedIds), Set(floatIds))

        let providers = try await expressRepository.providers()

        availableProviders = try providers.flatMap { provider -> [ExpressAvailableProvider] in
            guard allSet.contains(provider.id),
                  pair.source.supportedProvidersFilter.isSupported(provider: provider) else {
                return []
            }

            let supported: [ExpressProviderRateType] = [
                floatSet.contains(provider.id) ? .float : nil,
                fixedSet.contains(provider.id) ? .fixed : nil,
            ].compactMap { $0 }

            return try supported.map { rateType in
                try expressProviderManagerFactory.makeExpressProviderManager(
                    provider: provider,
                    pair: pair,
                    rateType: rateType
                )
            }
        }
    }

    func reloadQuotesInProviders() async -> [ExpressAvailableProvider] {
        defer { availableProviders.updateIsBestFlag(activeRateType: selectedAmountType?.rateType) }

        switch selectedAmountType {
        case .none:
            selectedProvider = nil
            availableProviders.forEach { $0.reset() }
            return availableProviders

        case .some(let amountType):
            let candidates = availableProviders.filter { $0.rateType == amountType.rateType }
            let names = candidates.map { $0.provider.name }.joined(separator: ", ")
            ExpressLogger.info(self, "Start a parallel updating in providers: \(names)")

            let tracker = ExpressQuotesLoadingPerformanceTracker.started(providersCount: candidates.count)

            await TaskGroup.executeKeepingOrder(items: candidates) { provider in
                var request = await self.makeRequest(amountType: amountType, provider: provider)
                request = request.with(quotesLoadingPerformanceTracker: tracker)

                await provider.updateState(request: request)
            }

            return candidates
        }
    }

    func makeRequest(amountType: ExpressAmountType, provider: ExpressAvailableProvider) -> ExpressManagerSwappingPairRequest {
        ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: provider.rateType,
            approvePolicy: selectedApprovePolicy,
            operationType: provider.pair.source.operationType
        )
    }

    func makeRequest(amountType: ExpressAmountType?, provider: ExpressAvailableProvider) throws -> ExpressManagerSwappingPairRequest {
        guard let amountType, amountType.amount > 0 else {
            ExpressLogger.info(self, "Skip update: amount is empty (nil or zero)")
            throw ExpressManagerError.amountNotFound
        }

        let request = makeRequest(amountType: amountType, provider: provider)
        return request
    }

    func currentResult() -> ExpressManagerUpdatingResult {
        let rateType = selectedAmountType?.rateType ?? .float
        let candidates = availableProviders.filter { $0.rateType == rateType }
        let supportedRateTypes = Set(availableProviders.map(\.rateType))

        let result = ExpressManagerUpdatingResult(
            providers: candidates,
            selected: selectedProvider,
            supportedRateTypes: supportedRateTypes
        )

        ExpressLogger.info(self, "Updating result: \(result.description)")
        return result
    }

    /// Fires `bestProviderSelected` analytics for the currently auto-selected provider.
    /// Call only from code paths that just (re)picked `selectedProvider` via `best()`.
    func logBestProviderSelected() {
        guard let selectedProvider else { return }
        selectedProvider.pair.source.analyticsLogger.bestProviderSelected(selectedProvider)
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
