//
//  CommonExpressManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

actor CommonExpressManager {
    // MARK: - Dependencies

    private let expressAPIProvider: ExpressAPIProvider
    private let expressProviderManagerFactory: ExpressProviderManagerFactory
    private let expressRepository: ExpressRepository
    private let logger: Logger

    // MARK: - State

    private var _pair: ExpressManagerSwappingPair?
    private var _approvePolicy: ExpressApprovePolicy = .unlimited
    private var _amount: Decimal?

    private var allProviders: [ExpressAvailableProvider] = []
    private var availableProviders: [ExpressAvailableProvider] {
        allProviders.filter { $0.isAvailable }
    }

    private var selectedProvider: ExpressAvailableProvider?

    init(
        expressAPIProvider: ExpressAPIProvider,
        expressProviderManagerFactory: ExpressProviderManagerFactory,
        expressRepository: ExpressRepository,
        logger: Logger
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.expressProviderManagerFactory = expressProviderManagerFactory
        self.expressRepository = expressRepository
        self.logger = logger
    }
}

// MARK: - ExpressManager

extension CommonExpressManager: ExpressManager {
    func getPair() -> ExpressManagerSwappingPair? {
        return _pair
    }

    func getAmount() -> Decimal? {
        return _amount
    }

    func getSelectedProvider() -> ExpressAvailableProvider? {
        return selectedProvider
    }

    func getAllProviders() -> [ExpressAvailableProvider] {
        return allProviders
    }

    func getApprovePolicy() -> ExpressApprovePolicy {
        return _approvePolicy
    }

    func updatePair(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState {
        assert(pair.source.expressCurrency != pair.destination.expressCurrency, "Pair has equal currencies")
        _pair = pair

        // Clear for reselected the best quote
        clearCache()

        return try await update()
    }

    func updateAmount(amount: Decimal?) async throws -> ExpressManagerState {
        _amount = amount

        return try await update()
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressManagerState {
        selectedProvider = provider

        return try await selectedProviderState()
    }

    func update(approvePolicy: ExpressApprovePolicy) async throws -> ExpressManagerState {
        guard _approvePolicy != approvePolicy else {
            log("ApprovePolicy already is \(approvePolicy)")
            return try await selectedProviderState()
        }

        _approvePolicy = approvePolicy

        let request = try makeRequest()
        await selectedProvider?.manager.update(request: request, approvePolicy: _approvePolicy)
        return try await selectedProviderState()
    }

    func update() async throws -> ExpressManagerState {
        try await updateState()
    }

    func requestData() async throws -> ExpressTransactionData {
        guard let selectedProvider = selectedProvider else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let request = try makeRequest()
        return try await selectedProvider.manager.sendData(request: request)
    }
}

// MARK: - Private

private extension CommonExpressManager {
    /// Return the state which checking the all properties
    func updateState() async throws -> ExpressManagerState {
        guard let pair = _pair else {
            log("ExpressManagerSwappingPair not found")
            throw ExpressManagerError.pairNotFound
        }

        // Just update availableProviders for this pair
        try await updateAvailableProviders(pair: pair)

        try Task.checkCancellation()

        guard let amount = _amount, amount > 0 else {
            log("Amount isn't set. Return .idle state")
            return .idle
        }

        let request = try makeRequest()
        await updateStatesInProviders(request: request, approvePolicy: _approvePolicy)

        try Task.checkCancellation()

        try await updateSelectedProviderIfNeeded()

        return try await selectedProviderState()
    }

    func selectedProviderState() async throws -> ExpressManagerState {
        guard let selectedProvider = selectedProvider else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let state = await selectedProvider.getState()
        log("Selected provider state: \(state)")

        switch state {
        case .idle:
            return .idle
        case .error(let error, _):
            throw error
        case .restriction(let restriction, let quote):
            return .restriction(restriction, quote: quote)
        case .permissionRequired(let permissionRequired):
            return .permissionRequired(permissionRequired)
        case .preview(let preview):
            return .previewCEX(preview)
        case .ready(let ready):
            return .ready(ready)
        }
    }

    func updateAvailableProviders(pair: ExpressManagerSwappingPair) async throws {
        let availableProviderIds = try await expressRepository.getAvailableProviders(for: pair)

        // Setup providers manager only once
        if availableProviders.isEmpty {
            let providers = try await expressRepository.providers()
            allProviders = providers
                .map { provider in
                    ExpressAvailableProvider(
                        provider: provider,
                        isBest: false,
                        isAvailable: availableProviderIds.contains(provider.id),
                        manager: expressProviderManagerFactory.makeExpressProviderManager(provider: provider)
                    )
                }
        }

        allProviders.forEach { provider in
            provider.isBest = false
            provider.isAvailable = availableProviderIds.contains(provider.provider.id)
        }
    }

    func updateSelectedProviderIfNeeded() async throws {
        let selectedIsError = await selectedProvider?.getState().isError

        // If we don't have selectedProvider
        // Or if selectedProvider has an error
        // just update it
        if selectedProvider == nil || selectedIsError == true {
            selectedProvider = await bestProvider()
        }
    }

    func updateIsBestFlag() async {
        let bestRate = await bestByRateProvider()
        availableProviders.forEach { provider in
            provider.isBest = provider.provider == bestRate?.provider
            log("Update provider \(provider.provider.name) isBest? - \(provider.isBest)")
        }
    }

    func bestProvider() async -> ExpressAvailableProvider? {
        // If we have more then one provider then selected the best
        if availableProviders.count > 1 {
            // Try to find the best with expectAmount
            if let bestByRateProvider = await bestByRateProvider() {
                return bestByRateProvider
            }
        }

        // If all availableProviders don't have the quote and the expectAmount
        // Just select the provider by priority
        let provider = await availableProviders.asyncSorted(sort: >, by: { await $0.getPriority() }).first

        return provider
    }

    func bestByRateProvider() async -> ExpressAvailableProvider? {
        var hasProviderWithQuote = false

        let bests = await availableProviders.asyncSorted(sort: >, by: { provider in
            if let expectAmount = await provider.getState().quote?.expectAmount {
                hasProviderWithQuote = true
                return expectAmount
            }

            return 0
        })

        if hasProviderWithQuote, let best = bests.first {
            return best
        }

        return nil
    }

    func updateStatesInProviders(request: ExpressManagerSwappingPairRequest, approvePolicy: ExpressApprovePolicy) async {
        let providers = availableProviders.map { $0.provider.name }.joined(separator: ", ")
        log("Start a parallel updating in providers: \(providers) with request \(request)")

        // Run a parallel asynchronous tasks
        await withTaskGroup(of: Void.self) { [weak self] taskGroup in
            await self?.availableProviders.forEach { provider in
                taskGroup.addTask {
                    await provider.manager.update(request: request, approvePolicy: approvePolicy)
                }
            }
        }

        // Update "isBest" flag after each provider's state updating
        await updateIsBestFlag()
    }

    func makeRequest() throws -> ExpressManagerSwappingPairRequest {
        guard let pair = _pair else {
            throw ExpressManagerError.pairNotFound
        }

        guard let amount = _amount, amount > 0 else {
            throw ExpressManagerError.amountNotFound
        }

        return ExpressManagerSwappingPairRequest(pair: pair, amount: amount)
    }

    func clearCache() {
        selectedProvider = nil
    }
}

extension CommonExpressManager {
    nonisolated func log(_ args: Any) {
        logger.debug("\(self) \(args)")
    }
}
