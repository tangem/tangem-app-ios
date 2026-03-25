//
//  CEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CEXExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let swappingPair: ExpressManagerSwappingPair
    private let expressFeeProvider: ExpressFeeProvider // a.k.a TokenFeeProvidersManager
    private let expressAPIProvider: ExpressAPIProvider
    private let mapper: ExpressManagerMapper

    // MARK: - State

    private var _state: ThreadSafeContainer<ExpressProviderManagerState> = .init(.idle)

    init(
        provider: ExpressProvider,
        swappingPair: ExpressManagerSwappingPair,
        expressFeeProvider: ExpressFeeProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper
    ) {
        self.provider = provider
        self.swappingPair = swappingPair
        self.expressFeeProvider = expressFeeProvider
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
    }
}

// MARK: - ExpressProviderManager

extension CEXExpressProviderManager: ExpressProviderManager {
    var pair: ExpressManagerSwappingPair { swappingPair }
    var feeProvider: any ExpressFeeProvider { expressFeeProvider }

    func getState() -> ExpressProviderManagerState {
        _state.read()
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        let state = await getState(request: request)
        ExpressLogger.info(self, "Update to \(state)")

        _state.mutate { $0 = state }
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        let quoteId = getQuoteId()
        let adjustedRequest = try await adjustRequest(request)

        let item = try mapper.makeExpressSwappableDataItem(pair: pair, request: adjustedRequest, providerId: provider.id, providerType: provider.type, quoteId: quoteId)

        let data = try await expressAPIProvider.exchangeData(item: item)
        try Task.checkCancellation()

        return data
    }
}

// MARK: - Private

private extension CEXExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            switch request.amountType {
            case .from:
                return try await getStateForFromAmount(request: request)
            case .to:
                return try await getStateForToAmount(request: request)
            }
        } catch let error as ExpressAPIError {
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

        } catch {
            return .error(error, quote: .none)
        }
    }

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

    func getQuoteId() -> String? {
        if case .preview(let preview) = _state.read() {
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
        let item = mapper.makeExpressSwappableItem(pair: pair, request: request, providerId: provider.id, providerType: provider.type)
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
}

// MARK: - CustomStringConvertible

extension CEXExpressProviderManager: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
