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
    private let logger: SwappingLogger

    // MARK: - State

    // 1. Here we start. External values and triggers for update
    private var _pair: ExpressManagerSwappingPair?
    private var _amount: Decimal?

    // 2. All provider in the express
    private var providers: [ExpressProvider] = []
    // 3. Here ids from `/pair` for each pair
    private var availableProviders: [ExpressProvider.Id] = []
    // 4. Here from all `providers` with filled the quote from `/quote`.
    private var availableQuotes: [ExpectedQuote] = []
    // 5. Here the provider with his quote which was selected from user
    private var selectedQuote: ExpectedQuote?

    private var spendersAwaitingApprove = Set<String>()

    init(
        expressAPIProvider: ExpressAPIProvider,
        allowanceProvider: AllowanceProvider,
        logger: SwappingLogger
    ) {
        self.expressAPIProvider = expressAPIProvider
        self.allowanceProvider = allowanceProvider
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

    func getAllQuotes() async -> [ExpectedQuote] {
        return availableQuotes
    }

    func getSelectedQuote() -> ExpectedQuote? {
        return selectedQuote
    }

    func updatePair(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState {
        assert(pair.source.expressCurrency != pair.destination.expressCurrency, "Pair has equal currencies")
        _pair = pair

        // Clear for reselected the best quote
        selectedQuote = nil

        return try await update()
    }

    func updateAmount(amount: Decimal?) async throws -> ExpressManagerState {
        _amount = amount

        // Clear for reselected the best quote
        selectedQuote = nil

        return try await update()
    }

    func updateSelectedProvider(provider: ExpressProvider) async throws -> ExpressManagerState {
        guard let quote = availableQuotes.first(where: { $0.provider == provider }) else {
            throw ExpressManagerError.availableQuotesForProviderNotFound
        }

        selectedQuote = quote

        return try await update()
    }

    func update() async throws -> ExpressManagerState {
        try await updateState()
    }

    func didSendApproveTransaction(for spender: String) async {
        spendersAwaitingApprove.insert(spender)
    }

    func requestData() async throws -> ExpressTransactionData {
        guard let pair = _pair else {
            throw ExpressManagerError.pairNotFound
        }

        guard let amount = _amount, amount > 0 else {
            throw ExpressManagerError.amountNotFound
        }

        guard let selectedQuote = selectedQuote else {
            throw ExpressManagerError.selectedProviderNotFound
        }

        let request = ExpressManagerSwappingPairRequest(pair: pair, amount: amount)
        let data = try await loadSwappingData(request: request, providerId: selectedQuote.provider.id)
        return data
    }
}

// MARK: - Private

private extension CommonExpressManager {
    /// Return the state which checking the all properties
    func updateState() async throws -> ExpressManagerState {
        guard let pair = _pair else {
            logger.debug("ExpressManagerSwappingPair not found")
            return .restriction(.pairNotFound, quote: .none)
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
            return .restriction(restriction, quote: selectedQuote)
        }

        // If we have only only on selectedQuote and it has an error state
        // Then stop request's sequence
        if let error = selectedQuote.error {
            throw error
        }

        switch selectedQuote.provider.type {
        case .dex:
            let data = try await loadSwappingData(request: request, providerId: selectedQuote.provider.id)
            try Task.checkCancellation()
            return .ready(data: data, quote: selectedQuote)
        case .cex:
            return .previewCEX(quote: selectedQuote)
        }
    }
}

// MARK: - Providers

private extension CommonExpressManager {
    func getProviders() async throws -> [ExpressProvider] {
        guard providers.isEmpty else {
            return providers
        }

        let providers = try await expressAPIProvider.providers()
        self.providers = providers

        return providers
    }

    @discardableResult
    func getAvailableProviders(pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        let providers = try await loadAvailableProviders(pair: pair)
        availableProviders = providers

        return providers
    }

    func loadAvailableProviders(pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        let pairs = try await expressAPIProvider.pairs(
            from: [pair.source.expressCurrency],
            to: [pair.destination.expressCurrency]
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
        availableQuotes = quotes

        return quotes
    }

    func getSelectedQuote(request: ExpressManagerSwappingPairRequest, quotes: [ExpectedQuote]) async throws -> ExpectedQuote {
        // If we don't have selectedQuote just update it
        guard let selectedQuote else {
            let best = try bestQuote(from: quotes)
            self.selectedQuote = best
            return best
        }

        // If the new quote has same provider
        if let quote = quotes.first(where: { $0.provider == selectedQuote.provider }) {
            self.selectedQuote = quote
            return quote
        }

        return selectedQuote
    }

    func loadQuotes(request: ExpressManagerSwappingPairRequest) async throws -> [ExpectedQuote] {
        let allProviders = try await getProviders()
        let availableProvidersIds = try await getAvailableProviders(pair: request.pair)

        try Task.checkCancellation()

        let quotes = await loadExpectedQuotes(request: request, providerIds: availableProvidersIds)

        // Find the best quote
        let best: ExpressQuote? = {
            // If we have only one quote it can't be the best
            guard quotes.count > 1 else {
                return nil
            }

            return quotes
                .compactMapValues { try? $0.get() }
                .max { $0.value.expectAmount < $1.value.expectAmount }?.value
        }()

        let allQuotes: [ExpectedQuote] = allProviders.map { provider in
            guard let loadedQuoteResult = quotes[provider.id] else {
                return ExpectedQuote(provider: provider, state: .notAvailable, isBest: false)
            }

            switch loadedQuoteResult {
            case .success(let quote):
                let isBest = best == quote
                return ExpectedQuote(provider: provider, state: .quote(quote), isBest: isBest)
            case .failure(let error as ExpressAPIError):
                if error.errorCode == .exchangeTooSmallAmountError, let minAmount = error.value?.amount {
                    return ExpectedQuote(provider: provider, state: .tooSmallAmount(minAmount: minAmount), isBest: false)
                }

                return ExpectedQuote(provider: provider, state: .error(error), isBest: false)
            case .failure(let error):
                return ExpectedQuote(provider: provider, state: .error(error), isBest: false)
            }
        }

        return allQuotes
    }

    func bestQuote(from quotes: [ExpectedQuote]) throws -> ExpectedQuote {
        // Find the best quote with provider
        guard let bestPossibleQuote = quotes.max(by: { $0.priority < $1.priority }) else {
            throw ExpressManagerError.quotesNotFound
        }

        return bestPossibleQuote
    }

    func loadExpectedQuotes(request: ExpressManagerSwappingPairRequest, providerIds: [ExpressProvider.Id]) async -> [ExpressProvider.Id: Result<ExpressQuote, Error>] {
        typealias TaskValue = (id: ExpressProvider.Id, result: Result<ExpressQuote, Error>)

        let quotes: [ExpressProvider.Id: Result<ExpressQuote, Error>] = await withTaskGroup(of: TaskValue.self) { [weak self] taskGroup in
            providerIds.forEach { providerId in

                // Run a parallel asynchronous task and collect it into the group
                _ = taskGroup.addTaskUnlessCancelled { [weak self] in
                    guard let self else {
                        return (providerId, .failure(ExpressManagerError.objectReleased))
                    }

                    do {
                        let item = await makeExpressSwappableItem(request: request, providerId: providerId)
                        let quote = try await expressAPIProvider.exchangeQuote(item: item)
                        return (providerId, .success(quote))
                    } catch {
                        return (providerId, .failure(error))
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

        if case .tooSmallAmount(let minAmount) = quote.state {
            return .notEnoughAmountForSwapping(minAmount)
        }

        // 2. Check Balance

        let sourceBalance = try await request.pair.source.getBalance()
        let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

        if isNotEnoughBalanceForSwapping {
            return .notEnoughBalanceForSwapping(request.amount)
        }

        // 3. Check Permission

        if let spender = quote.quote?.allowanceContract {
            do {
                let isPermissionRequired = try await isPermissionRequired(request: request, for: spender)

                if isPermissionRequired {
                    return .permissionRequired(spender: spender)
                }
            } catch AllowanceProviderError.approveTransactionInProgress {
                return .approveTransactionInProgress(spender: spender)
            } catch {
                throw error
            }
        }

        // No Restrictions
        return nil
    }

    // MARK: Permission

    func isPermissionRequired(request: ExpressManagerSwappingPairRequest, for spender: String) async throws -> Bool {
        let contractAddress = request.pair.source.expressCurrency.contractAddress

        if contractAddress == ExpressConstants.coinContractAddress {
            return false
        }

        assert(contractAddress != ExpressConstants.coinContractAddress)

        let allowanceWEI = try await allowanceProvider.getAllowance(
            owner: request.pair.source.defaultAddress,
            to: spender,
            contract: contractAddress
        )

        let allowance = request.pair.source.convertFromWEI(value: allowanceWEI)
        logger.debug("\(request.pair.source) allowance - \(allowance)")

        let approveTxWasSent = spendersAwaitingApprove.contains(spender)
        let hasEnoughAllowance = allowance >= request.amount
        if approveTxWasSent {
            if hasEnoughAllowance {
                spendersAwaitingApprove.remove(spender)
                return hasEnoughAllowance
            } else {
                throw AllowanceProviderError.approveTransactionInProgress
            }
        }
        return !hasEnoughAllowance
    }
}

// MARK: - Swapping Data

private extension CommonExpressManager {
    func loadSwappingData(request: ExpressManagerSwappingPairRequest, providerId: ExpressProvider.Id) async throws -> ExpressTransactionData {
        let item = makeExpressSwappableItem(request: request, providerId: providerId)
        let data = try await expressAPIProvider.exchangeData(item: item)
        return data
    }
}

// MARK: - Mapping

private extension CommonExpressManager {
    func makeExpressSwappableItem(request: ExpressManagerSwappingPairRequest, providerId: ExpressProvider.Id) -> ExpressSwappableItem {
        ExpressSwappableItem(
            source: request.pair.source,
            destination: request.pair.destination,
            amount: request.amount,
            providerId: providerId
        )
    }
}
