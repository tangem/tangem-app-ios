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

    private var availableProviders: AvailableProviders = .empty
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

    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerUpdatingResult {
        pair.map { assert($0.source.currency != $0.destination.currency, "Pair has equal currencies") }
        _pair = pair

        // Clear for reselected the best quote
        clearCache()

        switch pair {
        case .some(let pair): try await updateAvailableProviders(pair: pair)
        case .none: availableProviders = .empty
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

        let supported = providers.filter { provider in
            allSet.contains(provider.id) && pair.source.supportedProvidersFilter.isSupported(provider: provider)
        }

        let make = { (provider: ExpressProvider, rateType: ExpressProviderRateType) throws -> ExpressAvailableProvider in
            try self.expressProviderManagerFactory.makeExpressProviderManager(
                provider: provider,
                pair: pair,
                rateType: rateType
            )
        }

        let float = try supported.filter { floatSet.contains($0.id) }.map { try make($0, .float) }
        let fixed = try supported.filter { fixedSet.contains($0.id) }.map { try make($0, .fixed) }

        availableProviders = AvailableProviders(float: float, fixed: fixed)
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
        availableProviders.candidates(for: _amountType?.rateType)
    }

    func updateIsBestFlag() {
        let rateType = _amountType?.rateType ?? .float
        let providers = availableProviders.all
        providers.updateIsBestFlag(rateType: rateType)

        let summary = providers.map { "\($0.provider.name)=\($0.isBest)" }.joined(separator: ", ")
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
                let providerRequest = request.with(rateType: provider.rateType)
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

        let rateType: ExpressProviderRateType = provider?.rateType ?? amountType.rateType

        return ExpressManagerSwappingPairRequest(
            amountType: amountType,
            rateType: rateType,
            approvePolicy: _approvePolicy,
            operationType: pair.source.operationType
        )
    }

    func clearCache() {
        selectedProvider = nil
    }

    func makeUpdatingResult(selected: ExpressAvailableProvider?) -> ExpressManagerUpdatingResult {
        let result = ExpressManagerUpdatingResult(
            selected: selected,
            providers: candidateProviders,
            supportedRateTypes: availableProviders.supportedRateTypes
        )
        ExpressLogger.info(self, "Updating result: \(result.description)")
        return result
    }
}

// MARK: - CustomStringConvertible

extension CommonExpressManager: @preconcurrency CustomStringConvertible {
    var description: String { objectDescription(self) }
}

// MARK: - Types

extension CommonExpressManager {
    struct AvailableProviders {
        static let empty = AvailableProviders(float: [], fixed: [])

        let float: [ExpressAvailableProvider]
        let fixed: [ExpressAvailableProvider]

        var all: [ExpressAvailableProvider] { float + fixed }

        var supportedRateTypes: Set<ExpressProviderRateType> {
            var types: Set<ExpressProviderRateType> = []
            if !float.isEmpty { types.insert(.float) }
            if !fixed.isEmpty { types.insert(.fixed) }
            return types
        }

        func providers(for rateType: ExpressProviderRateType) -> [ExpressAvailableProvider] {
            switch rateType {
            case .float: float
            case .fixed: fixed
            }
        }

        /// Providers matching `rateType`; falls back to `all` if no providers match (or `rateType` is nil).
        func candidates(for rateType: ExpressProviderRateType?) -> [ExpressAvailableProvider] {
            guard let rateType else { return all }
            let preferred = providers(for: rateType)
            return preferred.isEmpty ? all : preferred
        }
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
