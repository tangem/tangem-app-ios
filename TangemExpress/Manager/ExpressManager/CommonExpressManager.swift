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

    func getAmount() -> Decimal? {
        return _amount
    }

    func getSelectedProvider() -> ExpressAvailableProvider? {
        return selectedProvider
    }

    func getAllProviders() -> [ExpressAvailableProvider] {
        return allProviders
    }

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressAvailableProvider? {
        pair.map { assert($0.source.currency != $0.destination.currency, "Pair has equal currencies") }
        _pair = pair

        // Clear for reselected the best quote
        clearCache()

        switch pair {
        case .some(let pair): try await updateAvailableProviders(pair: pair)
        case .none: allProviders.removeAll()
        }

        return try await update(by: .pairChange)
    }

    func update(amount: Decimal?, by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider? {
        _amount = amount

        return try await update(by: source)
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressAvailableProvider {
        selectedProvider = provider

        return try selectedProviderState()
    }

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressAvailableProvider {
        guard _approvePolicy != approvePolicy else {
            ExpressLogger.warning(self, "ApprovePolicy already is \(approvePolicy)")
            return try selectedProviderState()
        }

        _approvePolicy = approvePolicy

        let request = try makeRequest()
        await selectedProvider?.manager.update(request: request)
        return try selectedProviderState()
    }

    func update(feeOption: ExpressFee.Option) async throws -> ExpressAvailableProvider {
        guard _feeOption != feeOption else {
            ExpressLogger.warning(self, "ExpressFeeOption already is \(feeOption)")
            return try selectedProviderState()
        }

        _feeOption = feeOption

        let request = try makeRequest()
        await selectedProvider?.manager.update(request: request)
        return try selectedProviderState()
    }

    func update(by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider? {
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
    func updateState(by source: ExpressProviderUpdateSource) async throws -> ExpressAvailableProvider? {
        guard let pair = _pair else {
            ExpressLogger.warning("Pair isn't set. Return .idle state")
            return nil
        }

        try Task.checkCancellation()

        guard let amount = _amount, amount > 0 else {
            ExpressLogger.warning(self, "Amount isn't set. Return .idle state")
            return nil
        }

        let request = try makeRequest()
        await updateStatesInProviders(request: request)

        try Task.checkCancellation()

        await updateSelectedProvider(pair: pair, by: source)

        return try selectedProviderState()
    }

    func selectedProviderState() throws -> ExpressAvailableProvider {
        guard let selectedProvider = selectedProvider else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let state = selectedProvider.getState()
        ExpressLogger.info(self, "Selected provider state: \(state)")

        return selectedProvider
    }

    func updateAvailableProviders(pair: ExpressManagerSwappingPair) async throws {
        let availableProviderIds = try await expressRepository.getAvailableProviders(for: pair).toSet()
        let providers = try await expressRepository.providers()

        allProviders = try providers.map { provider in
            try makeExpressAvailableProvider(availableProviderIds: availableProviderIds, provider: provider, pair: pair)
        }
    }

    func makeExpressAvailableProvider(
        availableProviderIds: Set<String>,
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair
    ) throws -> ExpressAvailableProvider {
        guard let manager = expressProviderManagerFactory.makeExpressProviderManager(provider: provider, pair: pair) else {
            throw ExpressManagerError.unsupportedProviderType
        }

        let isSupportedBySource = pair.source.supportedProvidersFilter.isSupported(provider: provider)
        let isSupportedByExpress = availableProviderIds.contains(provider.id)
        let isAvailable = isSupportedBySource && isSupportedByExpress

        return ExpressAvailableProvider(
            provider: provider,
            isBest: false,
            isAvailable: isAvailable,
            manager: manager
        )
    }

    func updateSelectedProvider(pair: ExpressManagerSwappingPair, by source: ExpressProviderUpdateSource) async {
        if source.isRequiredUpdateSelectedProvider || selectedProvider == nil {
            selectedProvider = await bestProvider()

            if let selectedProvider {
                pair.source.analyticsLogger.bestProviderSelected(selectedProvider)
            }
        }
    }

    func updateIsBestFlag() async {
        let bestRate = await bestByRateProvider()

        let enabledProvidersMoreThanOne = await availableProviders
            .asyncCompactMap { provider -> ExpressQuote? in
                let state = provider.getState()
                return state.quote
            }
            .count > 1

        availableProviders.forEach { provider in
            // We set the `isBest` flag only if we have more than one enabled provider
            provider.isBest = enabledProvidersMoreThanOne && provider.provider == bestRate?.provider

            ExpressLogger.info(self, "Update provider \(provider.provider.name) isBest? - \(provider.isBest)")
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
        let provider = availableProviders.sorted(by: { $0.getPriority() > $1.getPriority() }).first

        return provider
    }

    func bestByRateProvider() async -> ExpressAvailableProvider? {
        var hasProviderWithQuote = false

        let bests = availableProviders.sorted(by: { lhsProvider, rhsProvider in
            let lhsExpectAmount = lhsProvider.getState().quote?.expectAmount
            let rhsExpectAmount = rhsProvider.getState().quote?.expectAmount

            hasProviderWithQuote = lhsExpectAmount != nil || rhsExpectAmount != nil

            if let lhsExpectAmount, let rhsExpectAmount {
                return lhsExpectAmount > rhsExpectAmount
            }

            return false
        })

        if hasProviderWithQuote, let best = bests.first {
            return best
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
            amount: amount,
            feeOption: _feeOption,
            approvePolicy: _approvePolicy,
            operationType: pair.source.operationType
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
