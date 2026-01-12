//
//  DEXExpressProviderManager.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor DEXExpressProviderManager {
    // MARK: - Dependencies

    private let provider: ExpressProvider
    private let expressAPIProvider: ExpressAPIProvider
    private let mapper: ExpressManagerMapper
    private let transactionValidator: ExpressProviderTransactionValidator

    // MARK: - State

    private var _state: ExpressProviderManagerState = .idle

    init(
        provider: ExpressProvider,
        expressAPIProvider: ExpressAPIProvider,
        mapper: ExpressManagerMapper,
        transactionValidator: ExpressProviderTransactionValidator
    ) {
        self.provider = provider
        self.expressAPIProvider = expressAPIProvider
        self.mapper = mapper
        self.transactionValidator = transactionValidator
    }
}

// MARK: - ExpressProviderManager

extension DEXExpressProviderManager: ExpressProviderManager {
    func getState() -> ExpressProviderManagerState {
        _state
    }

    func update(request: ExpressManagerSwappingPairRequest) async {
        let state = await getState(request: request)
        ExpressLogger.info(self, "Update to \(state)")
        _state = state
    }

    func sendData(request: ExpressManagerSwappingPairRequest) async throws -> ExpressTransactionData {
        guard case .ready(let state) = _state else {
            throw ExpressProviderError.transactionDataNotFound
        }

        return state.data
    }
}

// MARK: - Private

private extension DEXExpressProviderManager {
    func getState(request: ExpressManagerSwappingPairRequest) async -> ExpressProviderManagerState {
        do {
            let item = mapper.makeExpressSwappableItem(request: request, providerId: provider.id, providerType: provider.type)
            let quote = try await expressAPIProvider.exchangeQuote(item: item)

            if let restriction = await checkRestriction(request: request, quote: quote) {
                return restriction
            }

            let dataItem = try mapper.makeExpressSwappableDataItem(request: request, providerId: provider.id, providerType: provider.type)
            let data = try await expressAPIProvider.exchangeData(item: dataItem)
            try Task.checkCancellation()

            return try await proceed(request: request, quote: quote, data: data)

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

    func checkRestriction(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote) async -> ExpressProviderManagerState? {
        // Check Balance
        do {
            let sourceBalance = try request.pair.source.balanceProvider.getBalance()
            let isNotEnoughBalanceForSwapping = request.amount > sourceBalance

            if isNotEnoughBalanceForSwapping {
                return .restriction(.insufficientBalance(request.amount), quote: quote)
            }

            // Check fee currency balance at least more then zero
            guard request.pair.source.balanceProvider.feeCurrencyHasPositiveBalance else {
                return .restriction(.feeCurrencyHasZeroBalance, quote: quote)
            }

        } catch {
            return .error(error, quote: quote)
        }

        // Check Permission
        if let spender = quote.allowanceContract {
            do {
                let allowanceState = try await request.pair.source.allowanceProvider?.allowanceState(request: request, spender: spender)

                switch allowanceState {
                case .none:
                    throw ExpressProviderError.allowanceProviderNotFound
                case .enoughAllowance:
                    break
                case .permissionRequired(let approveData):
                    return .permissionRequired(
                        .init(provider: provider, policy: request.approvePolicy, data: approveData, quote: quote)
                    )
                case .approveTransactionInProgress:
                    return .restriction(.approveTransactionInProgress(spender: spender), quote: quote)
                }
            } catch {
                return .error(error, quote: quote)
            }
        }

        return nil
    }

    func proceed(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote, data: ExpressTransactionData) async throws -> ExpressProviderManagerState {
        if data.txValue > request.pair.source.balanceProvider.getFeeCurrencyBalance() {
            let estimateFee = try await estimateFee(request: request, data: data)
            return .restriction(estimateFee, quote: quote)
        }

        if let txData = data.txData, !transactionValidator.validateTransactionSize(data: txData) {
            throw ExpressProviderError.transactionSizeNotSupported
        }

        do {
            let ready = try await ready(request: request, quote: quote, data: data)
            return .ready(ready)
        } catch {
            let estimateFee = try await estimateFee(request: request, data: data)
            return .restriction(estimateFee, quote: quote)
        }
    }

    func estimateFee(request: ExpressManagerSwappingPairRequest, data: ExpressTransactionData) async throws -> ExpressRestriction {
        let otherNativeFee = data.otherNativeFee ?? 0

        if let estimatedGasLimit = data.estimatedGasLimit {
            let feeRequest = ExpressFeeRequest(provider: provider, option: request.feeOption)
            let estimateFee = try await request.pair.source.feeProvider.estimatedFee(
                request: feeRequest,
                estimatedGasLimit: estimatedGasLimit,
                otherNativeFee: otherNativeFee
            )
            return .feeCurrencyInsufficientBalanceForTxValue(estimateFee.amount.value)
        }

        let estimatedAmount = request.amount + otherNativeFee
        return .insufficientBalance(estimatedAmount)
    }

    func ready(request: ExpressManagerSwappingPairRequest, quote: ExpressQuote, data: ExpressTransactionData) async throws -> ExpressManagerState.Ready {
        let feeRequest = ExpressFeeRequest(provider: provider, option: request.feeOption)
        let fee = try await request.pair.source.feeProvider.transactionFee(
            request: feeRequest,
            data: .dex(data: data)
        )

        try Task.checkCancellation()

        // better to make the quote from the data
        let quoteData = ExpressQuote(fromAmount: data.fromAmount, expectAmount: data.toAmount, allowanceContract: quote.allowanceContract)
        return .init(provider: provider, feeOption: request.feeOption, data: data, quote: quoteData)
    }
}

// MARK: - CustomStringConvertible

extension DEXExpressProviderManager: @preconcurrency CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}
