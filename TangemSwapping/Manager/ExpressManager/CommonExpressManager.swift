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
    private let allowanceProvider: AllowanceProvider
    private let expressPendingTransactionRepository: ExpressPendingTransactionRepository
    private let logger: SwappingLogger

    // MARK: - State

    // 1. Here we start. External values and triggers for update
    private var _pair: ExpressManagerSwappingPair?
    private var _amount: Decimal?

    // 2. All provider in the express
    private let providers: CurrentValueSubject<[ExpressProvider], Never> = .init([])
    // 3. Here ids from `/pair` for each pair. Will see, maybe the cache will be deleted
    private let availableProviders: CurrentValueSubject<[ExpressManagerSwappingPair: [Int]], Never> = .init([:])
    // 4. Here from all `_providers` with filled the quote from `/quote`.
    // Will see, maybe the cache will be deleted
    private let availableQuotes: CurrentValueSubject<[ExpressManagerSwappingPair: [ExpectedQuote]], Never> = .init([:])
    // 5. Here the provider with his quote which was selected from user or autoselected as the best rate
    // Will see, maybe the cache will be deleted
    private let selectedQuote: CurrentValueSubject<[ExpressManagerSwappingPair: ExpectedQuote], Never> = .init([:])

    init(
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: AllowanceProvider,
        expressPendingTransactionRepository: ExpressPendingTransactionRepository,
        logger: SwappingLogger
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.allowanceProvider = allowanceProvider
        self.expressPendingTransactionRepository = expressPendingTransactionRepository
        self.logger = logger
    }
}

// MARK: - ExpressManager

extension CommonExpressManager: ExpressManager {
    func getPair() -> ExpressManagerSwappingPair? {
        _pair
    }

    func getAmount() -> Decimal? {
        _amount
    }

    func getSelectedProvider() -> ExpressProvider? {
        guard let pair = _pair else { return nil }

        return selectedQuote.value[pair]?.provider
    }

    nonisolated var providersPublisher: AnyPublisher<[ExpressProvider], Never> {
        providers.eraseToAnyPublisher()
    }

    nonisolated var availableQuotesPublisher: AnyPublisher<[ExpectedQuote], Never> {
        availableQuotes
            // Should setFailureType for asyncMap works
            .setFailureType(to: Error.self)
            .asyncMap { [weak self] quotes in
                if let pair = await self?._pair {
                    return quotes[pair] ?? []
                }

                self?.logger.debug("Pair not found")
                return []
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    nonisolated var selectedQuotePublisher: AnyPublisher<ExpectedQuote?, Never> {
        selectedQuote
            // Should setFailureType for asyncMap works
            .setFailureType(to: Error.self)
            .asyncMap { [weak self] quotes in
                if let pair = await self?._pair {
                    return quotes[pair]
                }

                self?.logger.debug("Pair not found")
                return nil
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    func updatePair(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState {
        _pair = pair

        return try await update()
    }

    func updateAmount(amount: Decimal?) async throws -> ExpressManagerState {
        _amount = amount

        return try await update()
    }

    func updateSelectedProvider(provider: ExpressProvider) async throws -> ExpressManagerState {
        guard let pair = _pair else {
            logger.debug("ExpressManagerSwappingPair not found")
            throw ExpressManagerError.pairNotFound
        }

        guard let quote = availableQuotes.value[pair]?.first(where: { $0.provider == provider }) else {
            throw ExpressManagerError.availableQuotesForProviderNotFound
        }

        selectedQuote.value[pair] = quote

        return try await update()
    }

    func update() async throws -> ExpressManagerState {
        try await getState()
    }
}

// MARK: - Private

private extension CommonExpressManager {
    /// Return the state which checking the all properties
    func getState() async throws -> ExpressManagerState {
        guard let pair = _pair else {
            logger.debug("ExpressManagerSwappingPair not found")
            return .idle
        }

        // Just update availableProviders for this pair
        try await getAvailableProviders(pair: pair)

        try Task.checkCancellation()

        guard let amount = _amount, amount > 0 else {
            logger.debug("Amount not found or less then 0")
            return .idle
        }

        let request = ExpressManagerSwappingPairRequest(pair: pair, amount: amount)
        let quotes = try await getQuotes(request: request)
        let selectedQuote = try await getSelectedQuote(request: request, quotes: quotes)

        try Task.checkCancellation()

        if let restriction = try await checkRestriction(request: request, quote: selectedQuote) {
            return .restriction(restriction)
        }

        let data = try await loadSwappingData(request: request, providerId: selectedQuote.provider.id)

        try Task.checkCancellation()

        return .ready(data: data)
    }
}

// MARK: - Providers

private extension CommonExpressManager {
    func getProviders() async throws -> [ExpressProvider] {
        guard providers.value.isEmpty else {
            return providers.value
        }

        let providers = try await expressAPIProvider.providers()
        self.providers.send(providers)

        return providers
    }

    @discardableResult
    func getAvailableProviders(pair: ExpressManagerSwappingPair) async throws -> [Int] {
        if let providers = availableProviders.value[pair] {
            return providers
        }

        let providers = try await loadAvailableProviders(pair: pair)
        availableProviders.value[pair] = providers

        return providers
    }

    func loadAvailableProviders(pair: ExpressManagerSwappingPair) async throws -> [Int] {
        let pairs = try await expressAPIProvider.pairs(
            from: [pair.source.currency],
            to: [pair.destination.currency]
        )

        guard let pair = pairs.first else {
            throw ExpressManagerError.availablePairNotFound
        }

        return pair.providers
    }
}

// MARK: - Quotes

private extension CommonExpressManager {
    /// This method will always send the request without cache
    func getQuotes(request: ExpressManagerSwappingPairRequest) async throws -> [ExpectedQuote] {
        let quotes = try await loadQuotes(request: request)
        availableQuotes.value[request.pair] = quotes

        return quotes
    }

    func getSelectedQuote(
        request: ExpressManagerSwappingPairRequest,
        quotes: [ExpectedQuote]
    ) async throws -> ExpectedQuote {
        if let quote = selectedQuote.value[request.pair] {
            return quote
        }

        let best = try bestQuote(from: quotes)
        selectedQuote.value[request.pair] = best

        return best
    }

    func loadQuotes(request: ExpressManagerSwappingPairRequest) async throws -> [ExpectedQuote] {
        let allProviders = try await getProviders()
        let availableProvidersIds = try await getAvailableProviders(pair: request.pair)

        try Task.checkCancellation()

        let quotes = await loadExpectedQuotes(request: request, providerIds: availableProvidersIds)
        let allQuotes: [ExpectedQuote] = allProviders.map { provider in
            if let loadedQuote = quotes[provider.id] {
                return ExpectedQuote(provider: provider, state: loadedQuote)
            }

            return ExpectedQuote(provider: provider, state: .notAvailable)
        }

        return allQuotes
    }

    func bestQuote(from quotes: [ExpectedQuote]) throws -> ExpectedQuote {
        let sortedQuotes = quotes.sorted { lhs, rhs in
            let lhsAmount = lhs.quote?.expectAmount ?? 0
            let rhsAmount = rhs.quote?.expectAmount ?? 0

            return lhsAmount > rhsAmount
        }

        guard let bestExpectedQuote = sortedQuotes.first else {
            throw ExpressManagerError.quotesNotFound
        }

        return bestExpectedQuote
    }

    func loadExpectedQuotes(request: ExpressManagerSwappingPairRequest, providerIds: [Int]) async -> [Int: ExpectedQuote.State] {
        typealias TaskValue = (id: Int, quote: ExpectedQuote.State)

        let quotes: [Int: ExpectedQuote.State] = await withTaskGroup(of: TaskValue.self) { [weak self] taskGroup in
            providerIds.forEach { providerId in

                // Run a parallel asynchronous task and collect it into the group
                _ = taskGroup.addTaskUnlessCancelled { [weak self] in
                    guard let self else {
                        return (providerId, .error("CommonError.objectReleased"))
                    }

                    do {
                        let item = await makeExpressSwappableItem(request: request, providerId: providerId)
                        let quote = try await expressAPIProvider.exchangeQuote(item: item)
                        return (providerId, .quote(quote))
                    } catch {
                        return (providerId, .error(error.localizedDescription))
                    }
                }
            }

            return await taskGroup.reduce(into: [:]) { result, tuple in
                let (provider, quote) = tuple
                result[provider] = quote
            }
        }

        return quotes
    }
}

// MARK: - Restrictions

private extension CommonExpressManager {
    func checkRestriction(request: ExpressManagerSwappingPairRequest, quote: ExpectedQuote) async throws -> ExpressManagerRestriction? {
        // 1. Check minimal amount
        if let minAmount = quote.quote?.minAmount, request.amount < minAmount {
            return .notEnoughAmountForSwapping(minAmount)
        }

        // 2. Check Permission

        if let spender = quote.quote?.allowanceContract {
            let isPermissionRequired = try await isPermissionRequired(request: request, for: spender)

            if isPermissionRequired {
                return .permissionRequired(spender: spender)
            }
        }

        // 3. Check Pending

        let hasPendingTransaction = expressPendingTransactionRepository.hasPending(for: request.pair.source.currency.network)

        if hasPendingTransaction {
            return .hasPendingTransaction
        }

        // 4. Check Balance

        let sourceBalance = try await request.pair.source.getBalance()
        let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

        if isNotEnoughBalanceForSwapping {
            return .notEnoughBalanceForSwapping
        }

        // No Restrictions
        return nil
    }

    // MARK: Permission

    func isPermissionRequired(request: ExpressManagerSwappingPairRequest, for spender: String) async throws -> Bool {
        let contractAddress = request.pair.source.currency.contractAddress

        assert(contractAddress != ExpressConstants.coinContractAddress)

        let allowance = try await allowanceProvider.getAllowance(
            owner: request.pair.source.address,
            to: spender,
            contract: contractAddress
        )

        return allowance < request.amount
    }
}

// MARK: - Swapping Data

private extension CommonExpressManager {
    func loadSwappingData(request: ExpressManagerSwappingPairRequest, providerId: Int) async throws -> ExpressTransactionData {
        let item = makeExpressSwappableItem(request: request, providerId: providerId)
        let data = try await expressAPIProvider.exchangeData(item: item, destinationAddress: item.destination.address)
        return data
    }
}

// MARK: - Mapping

private extension CommonExpressManager {
    func makeExpressSwappableItem(request: ExpressManagerSwappingPairRequest, providerId: Int) -> ExpressSwappableItem {
        ExpressSwappableItem(
            source: request.pair.source,
            destination: request.pair.destination,
            amount: request.amount,
            providerId: providerId
        )
    }
}
