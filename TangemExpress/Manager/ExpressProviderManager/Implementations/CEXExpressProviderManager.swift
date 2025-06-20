//
//  CEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor CEXExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let expressAPIProvider: ExpressAPIProvider
    private let mapper: ExpressManagerMapper

    // MARK: - State

    private var _state: ExpressProviderManagerState = .idle

    init(
        provider: ExpressProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper
    ) {
        self.provider = provider
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
    }
}

// MARK: - ExpressProviderManager

extension CEXExpressProviderManager: ExpressProviderManager {
    func getState() -> ExpressProviderManagerState {
        _state
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        let state = await getState(request: request)
        ExpressLogger.info(self, "Update to \(state)")
        _state = state
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        let estimatedFee = try await request.pair.source.feeProvider.estimatedFee(amount: request.amount)
        try Task.checkCancellation()

        let subtractFee = try subtractFee(request: request, estimatedFee: estimatedFee)
        let request = try makeSwappingPairRequest(request: request, subtractFee: subtractFee)
        let item = try mapper.makeExpressSwappableDataItem(request: request, providerId: provider.id, providerType: provider.type)

        let data = try await expressAPIProvider.exchangeData(item: item)
        try Task.checkCancellation()

        return data
    }
}

// MARK: - Private

private extension CEXExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            if try isNotEnoughBalanceForSwapping(request: request) {
                // If we don't have the balance just load a quotes for show them to a user
                let quote = try await loadQuote(request: request)
                return .restriction(.insufficientBalance(request.amount), quote: quote)
            }

            guard request.pair.source.balanceProvider.feeCurrencyHasPositiveBalance else {
                let quote = try await loadQuote(request: request)
                return .restriction(.feeCurrencyHasZeroBalance, quote: quote)
            }

            let estimatedFee = try await request.pair.source.feeProvider.estimatedFee(amount: request.amount)
            try Task.checkCancellation()

            let subtractFee = try subtractFee(request: request, estimatedFee: estimatedFee)

            guard try isEnoughAmountToSubtractFee(request: request, subtractFee: subtractFee) else {
                // The amount of the request isn't enough after the fee has been subtracted
                let quote = try await loadQuote(request: request)
                return .restriction(.insufficientBalance(request.amount), quote: quote)
            }

            let previewDataRequest = try makeSwappingPairRequest(request: request, subtractFee: subtractFee)
            let quote = try await loadQuote(request: previewDataRequest)
            let fee = ExpressFee(option: request.feeOption, variants: estimatedFee)
            return .preview(.init(fee: fee, subtractFee: subtractFee, quote: quote))

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

    func loadQuote(request: ExpressManagerSwappingPairRequest) async throws -> ExpressQuote {
        let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id, providerType: provider.type)
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
            pair: request.pair,
            amount: reducedAmount,
            feeOption: request.feeOption,
            approvePolicy: request.approvePolicy
        )
    }

    func isEnoughAmountToSubtractFee(request: ExpressManagerSwappingPairRequest, subtractFee: Decimal) throws -> Bool {
        request.amount > subtractFee
    }

    func isNotEnoughBalanceForSwapping(request: ExpressManagerSwappingPairRequest) throws -> Bool {
        let sourceBalance = try request.pair.source.balanceProvider.getBalance()
        let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

        return isNotEnoughBalanceForSwapping
    }

    func subtractFee(request: ExpressManagerSwappingPairRequest, estimatedFee: ExpressFee.Variants) throws -> Decimal {
        // The fee's subtraction needed only for fee currency
        guard request.pair.source.isFeeCurrency else {
            return 0
        }

        let balance = try request.pair.source.balanceProvider.getBalance()
        let fee = estimatedFee.fee(option: request.feeOption).amount.value
        let fullAmount = request.amount + fee

        // If we don't have enough balance
        guard fullAmount > balance else {
            return 0
        }

        // We're decreasing amount on the fee value
        ExpressLogger.info(self, "Subtract fee - \(fee) from amount - \(request.amount)")
        return fee
    }
}

// MARK: - CustomStringConvertible

extension CEXExpressProviderManager: @preconcurrency CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
