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
    private let analyticsLogger: ExpressAnalyticsLogger
    private let supportedProviderTypes: [ExpressProviderType]
    private let operationType: ExpressOperationType

    // MARK: - State

    private var _pair: ExpressManagerSwappingPair?
    private var _approvePolicy: ApprovePolicy = .unlimited
    private var _feeOption: ExpressFee.Option = .market
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
        analyticsLogger: ExpressAnalyticsLogger,
        supportedProviderTypes: [ExpressProviderType],
        operationType: ExpressOperationType
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.expressProviderManagerFactory = expressProviderManagerFactory
        self.expressRepository = expressRepository
        self.analyticsLogger = analyticsLogger
        self.supportedProviderTypes = supportedProviderTypes
        self.operationType = operationType
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

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState {
        pair.map { assert($0.source.currency != $0.destination.currency, "Pair has equal currencies") }
        _pair = pair

        // Clear for reselected the best quote
        clearCache()

        return try await update(by: .pairChange)
    }

    func update(amount: Decimal?, by source: ExpressProviderUpdateSource) async throws -> ExpressManagerState {
        _amount = amount

        return try await update(by: source)
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressManagerState {
        selectedProvider = provider

        return try await selectedProviderState()
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState {
        guard _approvePolicy != approvePolicy else {
            ExpressLogger.warning(self, "ApprovePolicy already is \(approvePolicy)")
            return try await selectedProviderState()
        }

        _approvePolicy = approvePolicy

        let request = try makeRequest()
        await selectedProvider?.manager.update(request: request)
        return try await selectedProviderState()
    }

    func update(feeOption: ExpressFee.Option) async throws -> ExpressManagerState {
        guard _feeOption != feeOption else {
            ExpressLogger.warning(self, "ExpressFeeOption already is \(feeOption)")
            return try await selectedProviderState()
        }

        _feeOption = feeOption

        let request = try makeRequest()
        await selectedProvider?.manager.update(request: request)
        return try await selectedProviderState()
    }

    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressManagerState {
        try await updateState(by: source)
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
    func updateState(by source: ExpressProviderUpdateSource) async throws -> ExpressManagerState {
        guard let pair = _pair else {
            ExpressLogger.warning("Pair isn't set. Return .idle state")
            return .idle
        }

        // Just update availableProviders for this pair
        try await updateAvailableProviders(pair: pair)

        try Task.checkCancellation()

        guard let amount = _amount, amount > 0 else {
            ExpressLogger.warning(self, "Amount isn't set. Return .idle state")
            return .idle
        }

        let request = try makeRequest()
        await updateStatesInProviders(request: request)

        try Task.checkCancellation()

        await updateSelectedProvider(by: source)

        return try await selectedProviderState()
    }

    func selectedProviderState() async throws -> ExpressManagerState {
        guard let selectedProvider = selectedProvider else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let state = await selectedProvider.getState()
        ExpressLogger.info(self, "Selected provider state: \(state)")

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
            let providers = try await expressRepository.providers().filter { supportedProviderTypes.contains($0.type) }
            allProviders = providers.compactMap { provider in
                guard let manager = expressProviderManagerFactory.makeExpressProviderManager(provider: provider) else {
                    return nil
                }

                return ExpressAvailableProvider(
                    provider: provider,
                    isBest: false,
                    isAvailable: availableProviderIds.contains(provider.id),
                    manager: manager
                )
            }
        }

        allProviders.forEach { provider in
            provider.isBest = false
            provider.isAvailable = availableProviderIds.contains(provider.provider.id)
        }
    }

    func updateSelectedProvider(by source: ExpressProviderUpdateSource) async {
        if source.isRequiredUpdateSelectedProvider || selectedProvider == nil {
            selectedProvider = await bestProvider()

            if let selectedProvider {
                analyticsLogger.bestProviderSelected(selectedProvider)
            }
        }
    }

    func updateIsBestFlag() async {
        let bestRate = await bestByRateProvider()
        availableProviders.forEach { provider in
            provider.isBest = provider.provider == bestRate?.provider
            ExpressLogger.info(self, "Update provider \(provider.provider.name) isBest? - \(provider.isBest)")
        }
    }

    func bestProvider() async -> ExpressAvailableProvider? {
        // If we have more then one provider then selected the best
        if availableProviders.count > 1 {
            if let recommendedProvider = await recommendedProvder() {
                return recommendedProvider
            }
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

    func recommendedProvder() async -> ExpressAvailableProvider? {
        for provider in availableProviders {
            if await provider.getState().isError {
                continue
            }

            if provider.provider.recommended == true {
                return provider
            }
        }

        return nil
    }

    func updateStatesInProviders(request: ExpressManagerSwappingPairRequest) async {
        let providers = availableProviders.map { $0.provider.name }.joined(separator: ", ")
        ExpressLogger.info(self, "Start a parallel updating in providers: \(providers) with request \(request)")

        // Run a parallel asynchronous tasks
        await withTaskGroup(of: Void.self) { [weak self] taskGroup in
            await self?.availableProviders.forEach { provider in
                taskGroup.addTask {
                    await provider.manager.update(request: request)
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

        return ExpressManagerSwappingPairRequest(
            pair: pair,
            amount: amount,
            feeOption: _feeOption,
            approvePolicy: _approvePolicy,
            operationType: operationType
        )
    }

    func clearCache() {
        selectedProvider = nil
        _feeOption = .market
    }
}

// MARK: - CustomStringConvertible

extension CommonExpressManager: @preconcurrency CustomStringConvertible {
    var description: String { objectDescription(self) }
}
