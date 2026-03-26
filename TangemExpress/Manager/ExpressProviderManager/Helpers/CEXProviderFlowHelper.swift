//
//  CEXProviderFlowHelper.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CEXProviderFlowHelper {
    let provider: ExpressProvider
    let pair: ExpressManagerSwappingPair
    let expressFeeProvider: ExpressFeeProvider
    let expressAPIProvider: ExpressAPIProvider
    let mapper: ExpressManagerMapper
    let providerTypeOverride: ExpressProviderType?

    init(
        provider: ExpressProvider,
        pair: ExpressManagerSwappingPair,
        expressFeeProvider: ExpressFeeProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        providerTypeOverride: ExpressProviderType? = nil
    ) {
        self.provider = provider
        self.pair = pair
        self.expressFeeProvider = expressFeeProvider
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.providerTypeOverride = providerTypeOverride
    }

    // MARK: - Public

    /// Full flow including quote call. Used by the dedicated CEXExpressProviderManager.
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            switch request.amountType {
            case .from:
                return try await getStateForFromAmount(request: request)
            case .to:
                return try await getStateForToAmount(request: request)
            }
        } catch let error as ExpressAPIError {
            return mapAPIError(error)
        } catch {
            return .error(error, quote: .none)
        }
    }

    /// Post-quote entry point. Used by CombinedExpressProviderManager after the flow type is resolved.
    /// For `.from` flow: checks balance/fee, computes subtractFee. If subtraction needed, re-calls quote with reduced amount.
    /// For `.to` flow: uses the provided quote directly.
    func processAfterQuote(quote: ExpressQuote, request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            switch request.amountType {
            case .from:
                return try await processFromAmountAfterQuote(quote: quote, request: request)
            case .to:
                return try await processToAmountAfterQuote(quote: quote, request: request)
            }
        } catch let error as ExpressAPIError {
            return mapAPIError(error)
        } catch {
            return .error(error, quote: .none)
        }
    }

    /// Lazily fetches exchange data on send. Used by both dedicated and Combined managers.
    func sendData(currentState: ExpressProviderManagerState, request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        let quoteId = getQuoteId(from: currentState)
        let adjustedRequest = try await adjustRequest(request)

        let item = try mapper.makeExpressSwappableDataItem(
            pair: pair,
            request: adjustedRequest,
            providerId: provider.id,
            providerType: resolvedProviderType,
            quoteId: quoteId
        )

        let data = try await expressAPIProvider.exchangeData(item: item)
        try Task.checkCancellation()

        return data
    }
}

// MARK: - Private

private extension CEXProviderFlowHelper {
    var resolvedProviderType: ExpressProviderType {
        providerTypeOverride ?? provider.type
    }

    // MARK: - Full flow (getState)

    func getStateForToAmount(request: ExpressManagerSwappingPairRequest) async throws -> ExpressProviderManagerState {
        let quote = try await loadQuote(request: request)

        if try isNotEnoughBalanceForSwapping(amount: quote.fromAmount) {
            return .restriction(.insufficientBalance(quote.fromAmount), quote: quote)
        }

        guard try expressFeeProvider.feeCurrencyHasPositiveBalance() else {
            let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
            return .restriction(.feeCurrencyHasZeroBalance(isFeeCurrency: isFeeCurrency), quote: quote)
        }

        let estimatedFee = try await expressFeeProvider.estimatedFee(amount: quote.fromAmount)
        try Task.checkCancellation()

        // In .to flow we can't subtract fee — reducing fromAmount would change what user receives.
        // Instead just check that balance covers fromAmount + fee.
        if try !canCoverFee(amount: quote.fromAmount, estimatedFee: estimatedFee) {
            return .restriction(.insufficientBalance(quote.fromAmount), quote: quote)
        }

        return .preview(.init(provider: provider, subtractFee: 0, quote: quote, fee: estimatedFee))
    }

    func getStateForFromAmount(request: ExpressManagerSwappingPairRequest) async throws -> ExpressProviderManagerState {
        if try isNotEnoughBalanceForSwapping(amount: request.amount) {
            let quote = try await loadQuote(request: request)
            return .restriction(.insufficientBalance(request.amount), quote: quote)
        }

        guard try expressFeeProvider.feeCurrencyHasPositiveBalance() else {
            let quote = try await loadQuote(request: request)
            let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
            return .restriction(.feeCurrencyHasZeroBalance(isFeeCurrency: isFeeCurrency), quote: quote)
        }

        let estimatedFee = try await expressFeeProvider.estimatedFee(amount: request.amount)
        try Task.checkCancellation()

        let subtractFee = try subtractFee(amount: request.amount, estimatedFee: estimatedFee)

        guard isEnoughAmountToSubtractFee(amount: request.amount, subtractFee: subtractFee) else {
            let quote = try await loadQuote(request: request)
            return .restriction(.insufficientBalance(request.amount), quote: quote)
        }

        let previewDataRequest = try makeSwappingPairRequest(request: request, subtractFee: subtractFee)
        let quote = try await loadQuote(request: previewDataRequest)

        return .preview(.init(provider: provider, subtractFee: subtractFee, quote: quote, fee: estimatedFee))
    }

    // MARK: - Post-quote flow (processAfterQuote)

    func processToAmountAfterQuote(quote: ExpressQuote, request: ExpressManagerSwappingPairRequest) async throws -> ExpressProviderManagerState {
        if try isNotEnoughBalanceForSwapping(amount: quote.fromAmount) {
            return .restriction(.insufficientBalance(quote.fromAmount), quote: quote)
        }

        guard try expressFeeProvider.feeCurrencyHasPositiveBalance() else {
            let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
            return .restriction(.feeCurrencyHasZeroBalance(isFeeCurrency: isFeeCurrency), quote: quote)
        }

        let estimatedFee = try await expressFeeProvider.estimatedFee(amount: quote.fromAmount)
        try Task.checkCancellation()

        if try !canCoverFee(amount: quote.fromAmount, estimatedFee: estimatedFee) {
            return .restriction(.insufficientBalance(quote.fromAmount), quote: quote)
        }

        return .preview(.init(provider: provider, subtractFee: 0, quote: quote, fee: estimatedFee))
    }

    func processFromAmountAfterQuote(quote: ExpressQuote, request: ExpressManagerSwappingPairRequest) async throws -> ExpressProviderManagerState {
        if try isNotEnoughBalanceForSwapping(amount: request.amount) {
            return .restriction(.insufficientBalance(request.amount), quote: quote)
        }

        guard try expressFeeProvider.feeCurrencyHasPositiveBalance() else {
            let isFeeCurrency = expressFeeProvider.isFeeCurrency(source: pair.source.currency)
            return .restriction(.feeCurrencyHasZeroBalance(isFeeCurrency: isFeeCurrency), quote: quote)
        }

        let estimatedFee = try await expressFeeProvider.estimatedFee(amount: request.amount)
        try Task.checkCancellation()

        let subtractFee = try subtractFee(amount: request.amount, estimatedFee: estimatedFee)

        guard isEnoughAmountToSubtractFee(amount: request.amount, subtractFee: subtractFee) else {
            return .restriction(.insufficientBalance(request.amount), quote: quote)
        }

        // If subtraction is needed, re-quote with reduced amount
        if subtractFee > 0 {
            let previewDataRequest = try makeSwappingPairRequest(request: request, subtractFee: subtractFee)
            let adjustedQuote = try await loadQuote(request: previewDataRequest)
            return .preview(.init(provider: provider, subtractFee: subtractFee, quote: adjustedQuote, fee: estimatedFee))
        }

        return .preview(.init(provider: provider, subtractFee: 0, quote: quote, fee: estimatedFee))
    }

    // MARK: - Shared helpers

    func getQuoteId(from state: ExpressProviderManagerState) -> String? {
        if case .preview(let preview) = state {
            return preview.quote.quoteId
        }
        return nil
    }

    func adjustRequest(_ request: ExpressManagerSwappingPairRequest) async throws -> ExpressManagerSwappingPairRequest {
        switch request.amountType {
        case .from:
            let estimatedFee = try await expressFeeProvider.estimatedFee(amount: request.amount)
            try Task.checkCancellation()

            let subtractFee = try subtractFee(amount: request.amount, estimatedFee: estimatedFee)
            return try makeSwappingPairRequest(request: request, subtractFee: subtractFee)
        case .to:
            return request
        }
    }

    func loadQuote(request: ExpressManagerSwappingPairRequest) async throws -> ExpressQuote {
        let item = mapper.makeExpressSwappableItem(
            pair: pair,
            request: request,
            providerId: provider.id,
            providerType: resolvedProviderType
        )
        let quote = try await expressAPIProvider.exchangeQuote(item: item)
        return quote
    }

    func makeSwappingPairRequest(request: ExpressManagerSwappingPairRequest, subtractFee: Decimal) throws -> ExpressManagerSwappingPairRequest {
        guard subtractFee > 0 else {
            return request
        }

        let reducedAmount = request.amount - subtractFee

        guard reducedAmount > 0 else {
            throw ExpressManagerError.notEnoughAmountToSubtractFee
        }

        return ExpressManagerSwappingPairRequest(
            amountType: .from(reducedAmount),
            feeOption: request.feeOption,
            approvePolicy: request.approvePolicy,
            operationType: request.operationType
        )
    }

    func isEnoughAmountToSubtractFee(amount: Decimal, subtractFee: Decimal) -> Bool {
        amount > subtractFee
    }

    func isNotEnoughBalanceForSwapping(amount: Decimal) throws -> Bool {
        let sourceBalance = try pair.source.balanceProvider.getBalance()
        return amount > sourceBalance
    }

    func canCoverFee(amount: Decimal, estimatedFee: BSDKFee) throws -> Bool {
        guard expressFeeProvider.isFeeCurrency(source: pair.source.currency) else {
            return true
        }

        let balance = try expressFeeProvider.feeCurrencyBalance()
        let fee = estimatedFee.amount.value
        return amount + fee <= balance
    }

    func subtractFee(amount: Decimal, estimatedFee: BSDKFee) throws -> Decimal {
        guard try !canCoverFee(amount: amount, estimatedFee: estimatedFee) else {
            return 0
        }

        let fee = estimatedFee.amount.value
        ExpressLogger.info(self, "Subtract fee - \(fee) from amount - \(amount)")
        return fee
    }

    func mapAPIError(_ error: ExpressAPIError) -> ExpressProviderManagerState {
        guard let amount = error.value?.amount else {
            return .error(error, quote: .none)
        }

        switch error.errorCode {
        case .exchangeTooSmallAmountError:
            return .restriction(.tooSmallAmount(amount), quote: .none)
        case .exchangeTooBigAmountError:
            return .restriction(.tooBigAmount(amount), quote: .none)
        default:
            return .error(error, quote: .none)
        }
    }
}

// MARK: - CustomStringConvertible

extension CEXProviderFlowHelper: CustomStringConvertible {
    var description: String {
        objectDescription("CEXProviderFlowHelper")
    }
}
