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

    private var currentState: ExpressManagerState = .idle

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
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        switch pair {
        case .some(let pair) where pair.isTransfer:
            currentState = .transfer

        case .some(let pair):
            let providers = try await makeAvailableProviders(pair: pair)
            currentState = .idle(providers: providers)

        case .none:
            currentState = .idle
        }

        return currentState
    }

    func update(amountType: ExpressAmountType?) async -> ExpressManagerState {
        guard case .swap(_, let providers) = currentState else {
            return currentState
        }

        switch amountType {
        case .none:
            // Reset all providers to idle
            providers.all.forEach { $0.reset() }

            update(state: .idle(providers: providers))
            return currentState

        // Workaround. We receive Amount.from. But we have only providers with fixed rate
        case .from(let amount) where providers.float.isEmpty:
            let candidates = providers.availableProviders(rate: .fixed)
            return await reloadQuotes(amountType: .to(amount), candidates: candidates)

        case .some(let amountType):
            let candidates = providers.availableProviders(rate: amountType.rateType)
            return await reloadQuotes(amountType: amountType, candidates: candidates)
        }
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState {
        guard case .swap(_, let providers) = currentState else {
            return currentState
        }

        update(state: .swap(selected: provider, providers: providers))
        return currentState
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState {
        guard case .swap(.some(let selectedProvider), _) = currentState else {
            return currentState
        }

        guard selectedProvider.approvePolicy != approvePolicy else {
            ExpressLogger.warning(self, "ApprovePolicy already is \(approvePolicy)")
            return currentState
        }

        await selectedProvider.update(approvePolicy: approvePolicy)

        return currentState
    }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState {
        guard case .swap(.some(let selectedProvider), let providers) = currentState else {
            return currentState
        }

        let candidates = providers.availableProviders(rate: selectedProvider.rateType)
        await reloadQuotes(candidates: candidates)

        if type.isRequiredUpdateSelectedProvider {
            update(state: stateWithBestProvider(from: candidates))
        }

        return currentState
    }

    func requestData() async throws -> ExpressTransactionData {
        guard case .swap(.some(let selectedProvider), _) = currentState else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        return try await selectedProvider.requestData()
    }
}

// MARK: - Private

private extension CommonExpressManager {
    func makeAvailableProviders(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState.Providers {
        async let allIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: nil)
        async let fixedIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .fixed)
        async let floatIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .float)
        let (allSet, fixedSet, floatSet) = await (Set(allIds), Set(fixedIds), Set(floatIds))

        let providers = try await expressRepository.providers()

        let supported = providers.filter { provider in
            allSet.contains(provider.id) && pair.source.supportedProvidersFilter.isSupported(provider: provider)
        }

        let make: (ExpressProvider, ExpressProviderRateType) throws -> ExpressAvailableProvider = { provider, rateType in
            try self.expressProviderManagerFactory
                .makeExpressProviderManager(provider: provider, pair: pair, rateType: rateType)
        }

        let float = try supported.filter { floatSet.contains($0.id) }.map { try make($0, .float) }
        let fixed = try supported.filter { fixedSet.contains($0.id) }.map { try make($0, .fixed) }

        return ExpressManagerState.Providers(float: float, fixed: fixed)
    }

    func reloadQuotes(amountType: ExpressAmountType, candidates: [ExpressAvailableProvider]) async -> ExpressManagerState {
        guard case .swap = currentState else {
            return currentState
        }

        await update(candidates: candidates) { provider, tracker in
            await provider.update(amountType: amountType, quotesLoadingPerformanceTracker: tracker)
        }

        if Task.isCancelled {
            return currentState
        }

        let newState = stateWithBestProvider(from: candidates)
        return update(state: newState)
    }

    func reloadQuotes(candidates: [ExpressAvailableProvider]) async {
        await update(candidates: candidates) { provider, tracker in
            await provider.updateState(quotesLoadingPerformanceTracker: tracker)
        }
    }

    func update(
        candidates: [ExpressAvailableProvider],
        action: @escaping (ExpressAvailableProvider, ExpressQuotesLoadingPerformanceTracker) async -> Void
    ) async {
        defer { candidates.updateIsBestFlag() }

        let names = candidates.map { $0.provider.name }.joined(separator: ", ")
        ExpressLogger.info(self, "Start a parallel updating in providers: \(names)")

        let tracker = ExpressQuotesLoadingPerformanceTracker.started(providersCount: candidates.count)

        await TaskGroup.executeKeepingOrder(items: candidates) { provider in
            await action(provider, tracker)
        }
    }

    @discardableResult
    func update(state: ExpressManagerState) -> ExpressManagerState {
        currentState = state
        ExpressLogger.info(self, "Updated state: \(state.description)")

        return state
    }

    func stateWithBestProvider(from candidates: [ExpressAvailableProvider]) -> ExpressManagerState {
        guard case .swap(let previousSelected, let providers) = currentState else {
            return currentState
        }

        let best = candidates.best()
        if let best, best !== previousSelected {
            best.pair.source.analyticsLogger.bestProviderSelected(best)
        }

        return .swap(selected: best, providers: providers)
    }
}

// MARK: - CustomStringConvertible

extension CommonExpressManager: @preconcurrency CustomStringConvertible {
    var description: String { objectDescription(self) }
}

// MARK: - ExpressManagerState+

extension ExpressManagerState {
    static func idle(providers: Providers) -> Self {
        return .swap(selected: .none, providers: providers)
    }
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
