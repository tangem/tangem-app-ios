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
    private let featureFlags: ExpressFeatureFlags

    // MARK: - Inputs

    private var _pair: ExpressManagerSwappingPair?
    private var _amountType: ExpressAmountType?
    private var _approvePolicy: ApprovePolicy = .specified

    // MARK: - State

    private var currentState: ExpressManagerState = .idle
    private var providersTask: Task<ExpressManagerState.Providers, Error>?

    init(
        expressAPIProvider: ExpressAPIProvider,
        expressProviderManagerFactory: ExpressProviderManagerFactory,
        expressRepository: ExpressRepository,
        featureFlags: ExpressFeatureFlags
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.expressProviderManagerFactory = expressProviderManagerFactory
        self.expressRepository = expressRepository
        self.featureFlags = featureFlags
    }
}

// MARK: - ExpressManager

extension CommonExpressManager: ExpressManager {
    func getCurrentPair() -> ExpressManagerSwappingPair? {
        _pair
    }

    func getAmountType() -> ExpressAmountType? {
        _amountType
    }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        _pair = pair

        switch pair {
        case .some(let pair) where pair.isTransfer:
            providersTask = nil
            return update(state: .transfer)

        case .some(let pair):
            let providers = try await loadProviders(for: pair)
            let selected = bestProvider(from: providers.availableProviders(rate: .float))
            return update(state: .swap(selected: selected, providers: providers))

        case .none:
            providersTask = nil
            return update(state: .idle)
        }
    }

    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState {
        _amountType = amountType

        try await waitProvidersTaskIfNeeded()

        guard case .swap(_, let providers) = currentState else {
            return currentState
        }

        switch amountType {
        case .none:
            // Reset all providers to idle
            providers.all.forEach { $0.reset() }
            let selected = bestProvider(from: providers.availableProviders(rate: .float))
            return update(state: .swap(selected: selected, providers: providers))

        // Fall back to fixed-rate providers when the caller sends `.from` but only fixed-rate providers exist.
        case .from where providers.availableProviders(rate: .float).isEmpty:
            let candidates = providers.availableProviders(rate: .fixed)
            return await reloadQuotes(candidates: candidates, type: .amount)

        case .some(let amountType):
            let candidates = providers.availableProviders(rate: amountType.rateType)
            return await reloadQuotes(candidates: candidates, type: .amount)
        }
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState {
        guard case .swap(_, let providers) = currentState else {
            return currentState
        }

        return update(state: .swap(selected: provider, providers: providers))
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState {
        guard _approvePolicy != approvePolicy else {
            ExpressLogger.warning(self, "ApprovePolicy already is \(approvePolicy)")
            return currentState
        }

        _approvePolicy = approvePolicy

        guard case .swap(.some(let selectedProvider), _) = currentState else {
            // Policy saved on the actor; will be applied on the next quote refresh.
            return currentState
        }

        let request = makeRequest()
        await selectedProvider.update(request: request)

        return currentState
    }

    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState {
        guard case .swap(.some(let selectedProvider), let providers) = currentState else {
            return currentState
        }

        let candidates = providers.availableProviders(rate: selectedProvider.rateType)
        return await reloadQuotes(candidates: candidates, type: type)
    }

    func requestData() async throws -> ExpressTransactionData {
        guard case .swap(.some(let selectedProvider), _) = currentState else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let request = makeRequest()
        return try await selectedProvider.requestData(request: request)
    }
}

// MARK: - Private

private extension CommonExpressManager {
    func waitProvidersTaskIfNeeded() async throws {
        guard let task = providersTask else { return }

        let providers = try await task.value

        // Check that task is still relevant after await (pair might have changed)
        guard providersTask == task else { return }

        let selected = bestProvider(from: providers.availableProviders(rate: .float))
        update(state: .swap(selected: selected, providers: providers))
    }

    func loadProviders(for pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState.Providers {
        // Create task FIRST so update(amountType:) can await it
        let task = Task { [expressRepository] in
            try await expressRepository.updateProvidersIds(for: pair)
            return try await self.makeAvailableProviders(pair: pair)
        }
        providersTask = task

        let providers = try await task.value
        // Clear only on success - next pair update will create new task
        providersTask = nil
        return providers
    }

    func makeAvailableProviders(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState.Providers {
        async let allIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: nil)
        async let fixedIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .fixed)
        async let floatIds = expressRepository.getAvailableProvidersIds(for: pair, rateType: .float)
        let (allSet, fixedSet, floatSet) = await (Set(allIds), Set(fixedIds), Set(floatIds))

        let providers = try await expressRepository.providers(for: pair)

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

    func reloadQuotes(candidates: [ExpressAvailableProvider], type: ExpressManagerUpdatingType) async -> ExpressManagerState {
        defer {
            if featureFlags.isChooseBestDEXEnabled {
                candidates.updateIsBestFlagPreferringDEX()
            } else {
                candidates.updateIsBestFlag()
            }
        }

        let names = candidates.map { $0.provider.name }.joined(separator: ", ")
        ExpressLogger.info(self, "Start a parallel updating in providers: \(names)")

        let tracker = ExpressQuotesLoadingPerformanceTracker.started(providersCount: candidates.count)
        let request = makeRequest(tracker: tracker)

        await TaskGroup.executeKeepingOrder(items: candidates) { provider in
            await provider.update(request: request)
        }

        if type.isRequiredUpdateSelectedProvider {
            return update(state: stateWithBestProvider(from: candidates))
        }

        return currentState
    }

    @discardableResult
    func update(state: ExpressManagerState) -> ExpressManagerState {
        currentState = state
        ExpressLogger.info(self, "Updated state: \(state.description)")

        return state
    }

    func bestProvider(from providers: [ExpressAvailableProvider]) -> ExpressAvailableProvider? {
        featureFlags.isChooseBestDEXEnabled ? providers.bestPreferringDEX() : providers.best()
    }

    func stateWithBestProvider(from candidates: [ExpressAvailableProvider]) -> ExpressManagerState {
        guard case .swap(let previousSelected, let providers) = currentState else {
            return currentState
        }

        let best = bestProvider(from: candidates)
        if let best, best !== previousSelected {
            best.pair.source.analyticsLogger.bestProviderSelected(best)
        }

        return .swap(selected: best, providers: providers)
    }

    func makeRequest(tracker: ExpressQuotesLoadingPerformanceTracker? = .none) -> ExpressAvailableProviderUpdatingRequest {
        ExpressAvailableProviderUpdatingRequest(
            amountType: _amountType,
            approvePolicy: _approvePolicy,
            quotesLoadingPerformanceTracker: tracker
        )
    }
}

// MARK: - CustomStringConvertible

extension CommonExpressManager: @preconcurrency CustomStringConvertible {
    var description: String { objectDescription(self) }
}
