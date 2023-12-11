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
    private let logger: SwappingLogger

    // MARK: - State

    private var _pair: ExpressManagerSwappingPair?
    private var _approvePolicy: SwappingApprovePolicy = .unlimited
    private var _amount: Decimal?

    private var availableProviders: [ExpressAvailableProvider] = []
    private var selectedProvider: ExpressAvailableProvider?

    init(
        expressAPIProvider: ExpressAPIProvider,
        expressProviderManagerFactory: ExpressProviderManagerFactory,
        expressRepository: ExpressRepository,
        logger: SwappingLogger
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.expressProviderManagerFactory = expressProviderManagerFactory
        self.expressRepository = expressRepository
        self.logger = logger
    }
}

// MARK: - ExpressManager

extension CommonExpressManager: ExpressManager {
    func getPair() async -> ExpressManagerSwappingPair? {
        return _pair
    }

    func getAmount() async -> Decimal? {
        return _amount
    }

    func getSelectedProvider() -> ExpressAvailableProvider? {
        return selectedProvider
    }

    func getAvailableProviders() -> [ExpressAvailableProvider] {
        return availableProviders
    }

    func getApprovePolicy() -> SwappingApprovePolicy {
        return _approvePolicy
    }

    func updatePair(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState {
        assert(pair.source.expressCurrency != pair.destination.expressCurrency, "Pair has equal currencies")
        _pair = pair

        // Clear for reselected the best quote
        selectedProvider = nil

        return try await update()
    }

    func updateAmount(amount: Decimal?) async throws -> ExpressManagerState {
        _amount = amount

        // Clear for reselected the best quote
        selectedProvider = nil

        return try await update()
    }

    func updateSelectedProvider(provider: ExpressAvailableProvider) async throws -> ExpressManagerState {
        selectedProvider = provider

        return try await selectedProviderState()
    }

    func update(approvePolicy: SwappingApprovePolicy) async throws -> ExpressManagerState {
        _approvePolicy = approvePolicy

        return try await update()
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

        switch await selectedProvider.getState() {
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
        let providers = try await expressRepository.providers()
        let availableProviderIds = try await expressRepository.getAvailableProviders(for: pair)
        availableProviders = providers
            .filter { availableProviderIds.contains($0.id) }
            .map { provider in
                ExpressAvailableProvider(
                    provider: provider,
                    isBest: false,
                    manager: expressProviderManagerFactory.makeExpressProviderManger(provider: provider)
                )
            }
    }

    func updateSelectedProviderIfNeeded() async throws {
        // If we don't have selectedQuote just update it
        guard selectedProvider == nil else {
            return
        }

        let best = await bestProvider()
        selectedProvider = best
    }

    func bestProvider() async -> ExpressAvailableProvider? {
        var best: (provider: ExpressAvailableProvider, amount: Decimal)?

        if availableProviders.count > 1 {
            for availableProvider in availableProviders {
                let state = await availableProvider.getState()
                log(
                    """
                    Looking for best provider
                    Current Best \(availableProvider.provider.name) state: \(state)
                    Attempt to Best: \(String(describing: best?.provider.provider.name)) amount: \(String(describing: best?.amount))
                    """
                )

                if let amount = state.quote?.expectAmount {
                    if let bestTuple = best {
                        if amount > bestTuple.amount {
                            best = (provider: availableProvider, amount: amount)
                        }
                    } else {
                        best = (provider: availableProvider, amount: amount)
                    }
                }
            }
        }

        if let (manager, amount) = best {
            log("Best provider \(manager.provider.name) with amount: \(amount)")
            manager.isBest = true
            return manager
        }

        // Workaround. Waiting for reasync keywork
        var priorities: [(ExpressAvailableProvider, ExpressProviderManagerState.Priority)] = []
        for availableProvider in availableProviders {
            let priority = await availableProvider.getState().priority
            log("Provider \(availableProvider.provider.name) has priority: \(priority)")
            priorities.append((availableProvider, priority))
        }

        return priorities.sorted(by: { $0.1 > $1.1 }).first?.0
    }

    func updateStatesInProviders(request: ExpressManagerSwappingPairRequest, approvePolicy: SwappingApprovePolicy) async {
        // Run a parallel asynchronous tasks
        await withTaskGroup(of: Void.self) { [weak self] taskGroup in
            await self?.availableProviders.forEach { provider in
                taskGroup.addTask {
                    await provider.manager.update(request: request, approvePolicy: approvePolicy)
                }
            }
        }
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
}

extension CommonExpressManager {
    nonisolated func log(_ args: Any) {
        logger.debug("\(self) \(args)")
    }
}
