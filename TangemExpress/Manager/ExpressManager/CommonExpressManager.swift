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

    func update(approvePolicy: ApprovePolicy) async throws -> ExpressAvailableProvider? {
        guard _approvePolicy != approvePolicy else {
            ExpressLogger.warning(self, "ApprovePolicy already is \(approvePolicy)")
            return selectedProvider
        }

        _approvePolicy = approvePolicy

        let request = try makeRequest()
        await selectedProvider?.manager.update(request: request)
        return selectedProvider
    }

    func update(feeOption: ExpressFee.Option) async throws -> ExpressAvailableProvider? {
        guard _feeOption != feeOption else {
            ExpressLogger.warning(self, "ExpressFeeOption already is \(feeOption)")
            return selectedProvider
        }

        _feeOption = feeOption

        let request = try makeRequest()
        await selectedProvider?.manager.update(request: request)
        return selectedProvider
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
        let (allSet, fixedSet) = await (Set(allIds), Set(fixedIds))

        let providers = try await expressRepository.providers()

        availableProviders = try providers.compactMap { provider in
            var rateTypes: Set<ExpressProviderRateType> = []
            // Every available provider can serve float (FROM) requests
            if allSet.contains(provider.id) { rateTypes.insert(.float) }
            if fixedSet.contains(provider.id) { rateTypes.insert(.fixed) }

            return try makeExpressAvailableProvider(
                availableProviderIds: allSet,
                supportedRateTypes: rateTypes,
                provider: provider,
                pair: pair
            )
        }
    }

    func makeExpressAvailableProvider(
        availableProviderIds: Set<String>,
        supportedRateTypes: Set<ExpressProviderRateType>,
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair
    ) throws -> ExpressAvailableProvider? {
        let isSupportedBySource = pair.source.supportedProvidersFilter.isSupported(provider: provider)
        let isSupportedByExpress = availableProviderIds.contains(provider.id)
        let isAvailable = isSupportedBySource && isSupportedByExpress

        guard isAvailable else {
            return nil
        }

        guard let manager = expressProviderManagerFactory.makeExpressProviderManager(provider: provider, pair: pair) else {
            throw ExpressManagerError.unsupportedProviderType
        }

        return ExpressAvailableProvider(provider: provider, manager: manager, supportedRateTypes: supportedRateTypes, isBest: false)
    }

    func updateSelectedProvider(pair: ExpressManagerSwappingPair, by source: ExpressProviderUpdateSource) async {
        if source.isRequiredUpdateSelectedProvider || selectedProvider == nil {
            selectedProvider = await bestProvider()

            if let selectedProvider {
                pair.source.analyticsLogger.bestProviderSelected(selectedProvider)
            }
        }
    }

    func updateIsBestFlag() {
        let candidates = availableProviders.filteredByRateType(_amountType?.rateType)
        let bestRate = bestByRateProvider(from: candidates)

        let enabledProvidersMoreThanOne = candidates.compactMap { provider -> ExpressQuote? in
            let state = provider.getState()
            return state.quote
        }
        .count > 1

        availableProviders.forEach { provider in
            // We set the `isBest` flag only if we have more than one enabled provider
            let isBest = enabledProvidersMoreThanOne && provider.provider == bestRate?.provider
            provider.update(isBest: isBest)

            ExpressLogger.info(self, "Update provider \(provider.provider.name) isBest? - \(provider.isBest)")
        }
    }

    func bestProvider() async -> ExpressAvailableProvider? {
        let candidates = availableProviders.filteredByRateType(_amountType?.rateType)

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
        let providers = candidates ?? availableProviders.filteredByRateType(_amountType?.rateType)
        let isFixedRate = _amountType?.rateType == .fixed

        guard providers.contains(where: { $0.getState().quote != nil }) else {
            return nil
        }

        return providers.sorted(by: { lhsProvider, rhsProvider in
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
        updateIsBestFlag()
    }

    func makeRequest() throws -> ExpressManagerSwappingPairRequest {
        guard let pair = _pair else {
            throw ExpressManagerError.pairNotFound
        }

        guard let amountType = _amountType, amountType.amount > 0 else {
            throw ExpressManagerError.amountNotFound
        }

        return ExpressManagerSwappingPairRequest(
            amountType: amountType,
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
